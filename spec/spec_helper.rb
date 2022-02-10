# frozen_string_literal: true

require 'poppays-tiktok-api-client'
require 'timecop'
require 'webmock/rspec'
require 'active_support/all'
require 'httparty'

# Set environmental variables
ENV['RAILS_ENV'] = 'test'
ENV['TIKTOK_CREATOR_MARKETPLACE_USER_ID_TEST'] = '7033500955417116674'
ENV['TIKTOK_BUSINESS_ACCESS_TOKEN_TEST'] = 'fea5d0aea970561bf880c54ae93e47706ba93849'
ENV['TIKTOK_APP_ID_TEST'] = '7033660228885282818'
ENV['TIKTOK_APP_SECRET_TEST'] = '0ad68fb99c0756e77a3bb87557bc61533dd95a1f'
