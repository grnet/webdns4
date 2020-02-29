source 'https://rubygems.org'

group :development, :test do
  gem 'pry-byebug'
end

group :development do
  gem 'rubocop', '0.35', require: false
  gem 'yard'
  gem 'yard-tomdoc'
  gem 'guard-yard'
  gem 'guard-minitest', require: false
  gem 'guard', require: false
  gem 'capistrano', '3.2.1', require: false # pkg:capistrano
end

group :production do
  gem 'unicorn' # pkg:unicorn
end

group :assets do
  gem 'coffee-rails', '4.0.1' # pkg: ryby-coffee-rails
end

# Lock jessie versions
#

gem 'rails', '4.1.8' # pkg:rails
gem 'i18n', '0.6.9'
gem 'json', '1.8.1'
gem 'mail', '2.6.1'
gem 'mime-types', '1.25'
gem 'minitest', '5.4.2'
gem 'rack', '1.5.2'
gem 'rack-test', '0.6.2'
gem 'rake', '12.3.3'
gem 'sprockets', '2.12.3'
gem 'sprockets-rails', '2.1.3'
gem 'thread_safe', '0.3.3'
gem 'tzinfo', '1.1.0'
gem 'will_paginate', '3.0.5'

gem 'mysql2', '0.3.16' # pkg:ruby-mysql2
gem 'jquery-rails', '3.1.2' # pkg:ruby-jquery-rails
gem 'state_machine', '1.2.0' # pkg: ruby-state-machine

gem 'nokogiri', '1.6.3'

# Worker
gem 'faraday', '0.9.0'
gem 'faraday_middleware', '0.9.1'

# Devise & dependencies
gem 'devise', '3.5.2' # pkg:ruby-devise
gem 'warden', '1.2.3'
gem 'bcrypt', '3.1.7'
gem 'orm_adapter', '0.5.0'
gem 'responders', '1.1.2'

group :test do
  gem 'factory_girl_rails', '4.4.1'
end
