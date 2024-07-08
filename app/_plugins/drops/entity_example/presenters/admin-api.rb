# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module AdminAPI
          class Base < Liquid::Drop
            BASE_URL = 'http://localhost:8001'.freeze

            URLS = {
              'consumer' => "#{BASE_URL}/consumers/",
              'route'    => "#{BASE_URL}/routes/",
              'service'  => "#{BASE_URL}/services/"
            }.freeze

            def initialize(target:, data:, entity_type:)
              @target      = target
              @data        = data
              @entity_type = entity_type
            end

            def url
              @url ||= self.class::URLS.fetch(@entity_type)
            end

            def data
              @data
            end
          end

          class Plugin < Base
            URLS = {
              'consumer' => "#{BASE_URL}/consumers/{consumerName|Id}/plugins",
              'route'    => "#{BASE_URL}/routes/{routeName|Id}/plugins",
              'service'  => "#{BASE_URL}/services/{serviceName|Id}/plugins"
            }.freeze

            def url
              @url ||= self.class::URLS.fetch(@target)
            end
          end
        end
      end
    end
  end
end
