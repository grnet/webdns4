ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'factory_girl_rails'

Dir[Rails.root.join('test/support/*.rb')].each { |f| require f }

module ActiveSupport
  class TestCase
    include FactoryGirl::Syntax::Methods
  end
end
