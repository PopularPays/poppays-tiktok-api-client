# frozen_string_literal: true

# All interaction with the TikTok API happens through the Tiktok::ApiClient. Use the `self.instance` method to create an
# instance of the api client.
# Constructor Params:
# - tcm_user_id: The TikTok Creator Marketplace ID. This can be found by logging into the TCM with a business account and viewing the account settings
# - access_token: This is the access token which is returned after connecting a TikTok business account to a TikTok app.
#                 This is usually between our Pop Pays business account (test or production) and one of our TikTok apps.
# - app_id: The ID of the TikTok app being used. We have three apps - production, test (used for test and staging environments) and local (dev local environment)
# - app_secret: The app secret
# - environment: The environment the api client is running in - production, test or local
module Tiktok
  class ApiClient
    CREATOR_INSIGHTS_ENDPOINT_URL = 'https://business-api.tiktok.com/open_api/v1.2/creator/get/'
    AUTHORIZE_CREATOR_ENDPOINT_URL = 'https://business-api.tiktok.com/open_api/oauth2/token/?business=tt_user'

    def initialize(tcm_user_id, access_token, app_id, app_secret, environment, log_requests)
      @tcm_user_id = tcm_user_id.to_i
      @access_token = access_token
      @app_id = app_id
      @app_secret = app_secret
      @environment = environment
      @log_requests = log_requests
    end

    def self.production(log_requests: false)
      new(
        ENV['TIKTOK_CREATOR_MARKETPLACE_USER_ID_PRODUCTION'],
        ENV['TIKTOK_BUSINESS_ACCESS_TOKEN_PRODUCTION'],
        ENV['TIKTOK_APP_ID_PRODUCTION'],
        ENV['TIKTOK_APP_SECRET_PRODUCTION'],
        'production',
        log_requests
      )
    end

    def self.test(log_requests: false)
      new(
        ENV['TIKTOK_CREATOR_MARKETPLACE_USER_ID_TEST'],
        ENV['TIKTOK_BUSINESS_ACCESS_TOKEN_TEST'],
        ENV['TIKTOK_APP_ID_TEST'],
        ENV['TIKTOK_APP_SECRET_TEST'],
        'test',
        log_requests
      )
    end

    def self.local(log_requests: false)
      new(
        ENV['TIKTOK_CREATOR_MARKETPLACE_USER_ID_TEST'],
        ENV['TIKTOK_BUSINESS_ACCESS_TOKEN_LOCAL'],
        ENV['TIKTOK_APP_ID_LOCAL'],
        ENV['TIKTOK_APP_SECRET_LOCAL'],
        'local',
        log_requests
      )
    end

    private_class_method :new, :production, :test, :local

    # @param log_requests - Set to `true` if you want to print the request logs to console
    def self.instance(log_requests: false)
      rails_env = ENV['RAILS_ENV'].downcase

      if rails_env == 'test' || (!ENV['RAILS_ENV'].nil? && ENV['RAILS_ENV'] == 'staging') # for test and staging environments
        test(log_requests: log_requests)
      elsif rails_env == 'development'
        local(log_requests: log_requests)
      elsif rails_env == 'production'
        production(log_requests: log_requests)
      else
        local(log_requests: log_requests)
      end
    end

    # API Docs: https://ads.tiktok.com/marketing_api/docs?id=1712126292364289
    # Generates access token and refresh token for creator
    def authorize_creator(auth_code)
      grant_type = 'authorization_code'

      response = make_request(
        'POST',
        AUTHORIZE_CREATOR_ENDPOINT_URL,
        body: { client_id: @app_id, client_secret: @app_secret, grant_type: grant_type, auth_code: auth_code }
      )

      response_body = JSON.parse(response.body)
      now = DateTime.now

      {
        creator_id: response_body.dig('creator_id'),
        access_token: response_body.dig('access_token'),
        refresh_token: response_body.dig('refresh_token'),
        access_token_expiration: now + response_body.dig('expires').seconds,
        refresh_token_expiration: now + response_body.dig('refresh_expires').seconds,
        access_scope: response_body.dig('scope')
      }
    end

    # API Docs: https://ads.tiktok.com/marketing_api/docs?id=1712126292364289
    # Renews a creator's access token using their refresh token
    def refresh_access_token(refresh_token)
      grant_type = 'refresh_token'

      response = make_request(
        'POST',
        AUTHORIZE_CREATOR_ENDPOINT_URL,
        body: { client_id: @app_id, client_secret: @app_secret, grant_type: grant_type, refresh_token: refresh_token }
      )

      response_body = JSON.parse(response.body)
      now = DateTime.now

      {
        creator_id: response_body.dig('creator_id'),
        access_token: response_body.dig('access_token'),
        refresh_token: response_body.dig('refresh_token'),
        access_token_expiration: now + response_body.dig('expires').seconds,
        refresh_token_expiration: now + response_body.dig('refresh_expires').seconds,
        access_scope: response_body.dig('scope')
      }
    end

    # API Docs: https://ads.tiktok.com/marketing_api/docs?id=1712130383437825
    # Gets information about a given creator such as display name, handle, follower count, etc
    def creator_insights(creator_id, creator_access_token)
      response = make_request(
        'GET',
        CREATOR_INSIGHTS_ENDPOINT_URL,
        query_params: { creator_id: creator_id, fields: '["profile_image", "display_name", "followers_count", "audience_countries", "audience_genders", "audience_ages", "audience_locales", "handle_name"]' },
        headers: { 'Access-Token' => creator_access_token }
      )

      response_body = JSON.parse(response.body)

      {
        display_name: response_body.dig('data', 'display_name'),
        handle: response_body.dig('data', 'handle_name') || response_body.dig('data', 'display_name'),
        followers_count: response_body.dig('data', 'followers_count'),
        profile_image: response_body.dig('data', 'profile_image')
      }
    end

    private

    # generic method for sending a request to a given URL
    def make_request(http_method, url, body: {}, query_params: {}, headers: {})
      response = HTTParty.send(
        http_method.downcase,
        url,
        request_params(body, query_params, headers)
      )

      check_response_errors(response)

      response
    end

    def request_params(body, query_params, headers)
      params = {
        body: body.empty? ? nil : body.to_json,
        query: query_params.empty? ? nil : query_params,
        headers: default_headers.merge(headers)
      }

      if @log_requests
        params.merge!(debug_output: $stdout)
      end

      params
    end

    # Checks the response from TikTok for errors.
    # Raises an error if response contains an error or HTTP response code is a non-2XX
    def check_response_errors(response)
      response_body = JSON.parse(response.body)
      response_code = response_body.dig('code')
      response_message = response_body.dig('message')

      if errors?(response, response_code)
        case response_code
        when 40_102 # The access token has expired
          raise Tiktok::AccessTokenExpired, "#{response_code} -- #{response_message}"
        when 40_700 # Access token is invalid
          raise Tiktok::AccessTokenInvalid, "#{response_code} -- #{response_message}"
        else
          Raven.capture_message("There was an error with the TikTok API -- Error Code: #{response_code} - Error Message: #{response_message}")
          raise Tiktok::ApiError, "#{response_code} -- #{response_message}"
        end
      end

    # Sometimes the TikTok API returns a normal string (non-json) in the request body
    # This catches the error that's thrown by JSON.parse()
    rescue JSON::ParserError
      Raven.capture_message("There was an error with the TikTok API -- Error Code: null - Error Message: #{response.body}")
      raise Tiktok::ApiError, response.body
    end

    # if tiktok returns an error in the response body OR the HTTP response status code is >= 300
    # Sometimes tiktok doesn't return a code in a successful response so there's a check to
    # make sure the code is not nil.
    def errors?(response, code)
      (code != 0 && !code.nil? && response.code < 300) || response.code >= 300
    end

    def default_headers
      {
        'Content-Type' => 'application/json'
      }
    end
  end
end
