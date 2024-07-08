# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module Konnect
          class Base < Liquid::Drop
            BASE_URL = 'https://{us|eu}.api.konghq.com/v2/control-planes/{controlPlaneId}/core-entities'.freeze

            URLS = {
              'consumer' => "#{BASE_URL}/consumers/",
              'route'    => "#{BASE_URL}/routes/",
              'service'  => "#{BASE_URL}/services/"
            }.freeze

            def initialize(data:, target:, entity_type:)
              @data        = data
              @target      = target
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
              'consumer'       => "#{BASE_URL}/consumers/{consumerId}/plugins/",
              'consumer_group' => "#{BASE_URL}/consumer_groups/{consumerGroupId}/plugins/",
              'global'         => "#{BASE_URL}/plugins/",
              'route'          => "#{BASE_URL}/routes/{routeId}/plugins/",
              'service'        => "#{BASE_URL}/services/{serviceId}/plugins/"
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
