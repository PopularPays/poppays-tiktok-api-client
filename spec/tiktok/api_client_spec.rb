# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Tiktok::ApiClient do
  let(:creator_id) { '93a7dea1-c49b-47e3-ba54-715c63aeac93' }
  let(:access_token) { 'j3f09j2309j3f029jf093li3fjlk3fj90' }
  let(:display_name) { 'tiktok_display_name' }
  let(:handle_name) { 'tiktok_handle_name' }
  let(:profile_image) { 'https://www.rd.com/wp-content/uploads/2017/09/01-shutterstock_476340928-Irina-Bg.jpg' }
  let(:api_client) { Tiktok::ApiClient.instance }
  let(:followers_count) { 3848 }

  describe '#creator_insights' do
    let(:response_body) {
      {
        data: {
          display_name: display_name,
          handle_name: handle_name,
          profile_image: profile_image,
          followers_count: followers_count
        }
      }.to_json
    }

    before do
      stub_request(:get, "#{Tiktok::ApiClient::CREATOR_INSIGHTS_ENDPOINT_URL}?creator_id=#{creator_id}&fields=[\"profile_image\", \"display_name\", \"followers_count\", \"audience_countries\", \"audience_genders\", \"audience_ages\", \"audience_locales\", \"handle_name\"]")
        .with(headers: { 'Access-Token' => access_token, 'Content-Type' => 'application/json' }).to_return(body: response_body)
    end

    it 'returns creator insights' do
      creator_insights = api_client.creator_insights(creator_id, access_token)

      expect(creator_insights.dig(:display_name)).to eq(display_name)
      expect(creator_insights.dig(:handle)).to eq(handle_name)
      expect(creator_insights.dig(:profile_image)).to eq(profile_image)
      expect(creator_insights.dig(:followers_count)).to eq(followers_count)
    end
  end

  describe '#authorize_creator' do
    let(:refresh_token) { '3f0-29j203j23p09j2f309j23f093f3f90j3f03f' }
    let(:access_token_expiration) { DateTime.now + expires.seconds }
    let(:refresh_token_expiration) { DateTime.now + refresh_expires.seconds }
    let(:expires) { 86400 }
    let(:refresh_expires) { 31536000 }
    let(:app_id) { ENV['TIKTOK_APP_ID_TEST'] }
    let(:app_secret) { ENV['TIKTOK_APP_SECRET_TEST'] }
    let(:grant_type) { 'authorization_code' }
    let(:auth_code) { 'ox4o87jx34o87x4oj78x3o7m8x2mo7ct67ct6191c01c038c378383081c3c3c' }
    let(:scope) { 'user.info.basic,tcm.order.update,user.insights.creator,video.list' }

    let(:response_body) {
      {
        creator_id: creator_id,
        access_token: access_token,
        refresh_token: refresh_token,
        expires: expires,
        refresh_expires: refresh_expires,
        scope: scope
      }.to_json
    }

    before do
      stub_request(:post, "#{Tiktok::ApiClient::AUTHORIZE_CREATOR_ENDPOINT_URL}")
        .with(
          headers: { 'Content-Type' => 'application/json' },
          body: { client_id: app_id, client_secret: app_secret, grant_type: grant_type, auth_code: auth_code }.to_json
        ).to_return(body: response_body)
      Timecop.freeze
    end

    after do
      Timecop.return
    end

    it 'returns creator authorization info' do
      creator_authorization = api_client.authorize_creator(auth_code)

      expect(creator_authorization.dig(:creator_id)).to eq(creator_id)
      expect(creator_authorization.dig(:access_token)).to eq(access_token)
      expect(creator_authorization.dig(:refresh_token)).to eq(refresh_token)
      expect(creator_authorization.dig(:access_token_expiration)).to eq(access_token_expiration)
      expect(creator_authorization.dig(:refresh_token_expiration)).to eq(refresh_token_expiration)
      expect(creator_authorization.dig(:access_scope)).to eq(scope)
    end
  end

  describe '#refresh_access_token' do
    let(:refresh_token) { '3f0-29j203j23p09j2f309j23f093f3f90j3f03f' }
    let(:access_token_expiration) { DateTime.now + expires.seconds }
    let(:refresh_token_expiration) { DateTime.now + refresh_expires.seconds }
    let(:expires) { 86400 }
    let(:refresh_expires) { 31536000 }
    let(:app_id) { ENV['TIKTOK_APP_ID_TEST'] }
    let(:app_secret) { ENV['TIKTOK_APP_SECRET_TEST'] }
    let(:grant_type) { 'refresh_token' }
    let(:scope) { 'user.info.basic,tcm.order.update,user.insights.creator,video.list' }

    let(:response_body) {
      {
        creator_id: creator_id,
        access_token: access_token,
        refresh_token: refresh_token,
        expires: expires,
        refresh_expires: refresh_expires,
        scope: scope
      }.to_json
    }

    before do
      stub_request(:post, "#{Tiktok::ApiClient::AUTHORIZE_CREATOR_ENDPOINT_URL}")
        .with(
          headers: { 'Content-Type' => 'application/json' },
          body: { client_id: app_id, client_secret: app_secret, grant_type: grant_type, refresh_token: refresh_token }.to_json
        ).to_return(body: response_body)
      Timecop.freeze
    end

    after do
      Timecop.return
    end

    it 'returns creator authorization info' do
      authorization = api_client.refresh_access_token(refresh_token)

      expect(authorization.dig(:creator_id)).to eq(creator_id)
      expect(authorization.dig(:access_token)).to eq(access_token)
      expect(authorization.dig(:refresh_token)).to eq(refresh_token)
      expect(authorization.dig(:access_token_expiration)).to eq(access_token_expiration)
      expect(authorization.dig(:refresh_token_expiration)).to eq(refresh_token_expiration)
      expect(authorization.dig(:access_scope)).to eq(scope)
    end
  end
end
