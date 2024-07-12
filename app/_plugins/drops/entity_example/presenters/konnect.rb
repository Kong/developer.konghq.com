# frozen_string_literal: true

require_relative '../utils/variable_replacer'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module Konnect
          class Base < Liquid::Drop
            BASE_URL = 'https://{us|eu}.api.konghq.com/v2/control-planes/{controlPlaneId}/core-entities'.freeze

            URLS = {
              'consumer'       => "#{BASE_URL}/consumers/",
              'consumer_group' => "#{BASE_URL}/consumer_groups/",
              'route'          => "#{BASE_URL}/routes/",
              'service'        => "#{BASE_URL}/services/"
            }.freeze

            def initialize(data:, target:, entity_type:, variables:)
              @data        = data
              @target      = target
              @entity_type = entity_type
              @variables   = variables
            end

            def url
              @url ||= Utils::VariableReplacer::URL.run(
                string: self.class::URLS.fetch(@entity_type),
                variables: @variables
              )
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
              @url ||= Utils::VariableReplacer::URL.run(
                string: self.class::URLS.fetch(@target),
                variables: @variables
              )
            end
          end
        end
      end
    end
  end
end
