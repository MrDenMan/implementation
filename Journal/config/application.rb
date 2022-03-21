require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Src
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.after_initialize do
      sleep 5
      require 'bunny'
      require 'json'


      connection = Bunny.new('amqp://guest:guest@rabbitmq')
      connection.start

      channel = connection.create_channel

      exchange = channel.default_exchange
      queue_name = 'event.control'

      q = channel.queue('event.control', auto_delete: true)
      q.subscribe do |_delivery_info, properties, payload|
          #{"direction": "in", "status": "true", "event_id": 1, "visitor_id": 1}
          puts "============================="
          res = JSON.parse(payload)          
          puts res
          Journal.create(direction: res[:direction].to_s, event_id: res[:event_id].to_i, visitor_id: res[:visitor_id].to_i, status: res[:status].to_s)
          puts "============================="
      end
    end
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end

