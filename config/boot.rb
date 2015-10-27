# Set up gems listed in the Gemfile.

# Production doesn't use bundler
if ENV['RAILS_ENV'] != 'production'
  ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

  require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
end
