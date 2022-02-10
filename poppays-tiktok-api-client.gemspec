Gem::Specification.new do |spec|
  spec.name = 'poppays-tiktok-api-client'
  spec.version = '0.0.2'
  spec.required_ruby_version = '>= 2.5.0'
  spec.add_development_dependency 'rspec', '~> 3.7'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'webmock'
  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'httparty'
  spec.add_runtime_dependency 'sentry-raven'
  spec.files = %w[lib/tiktok/api_client.rb lib/poppays-tiktok-api-client.rb lib/tiktok/access_token_expired.rb lib/tiktok/access_token_invalid.rb lib/tiktok/api_error.rb]
  spec.post_install_message = 'Thanks for installing the Popular Pays TikTok API Client!'
  spec.summary = 'Popular Pays TikTok API Client'
  spec.authors = ['Popular Pays', 'Ian Pierce']
end
