# frozen_string_literal: true

require_relative '../utils/variable_replacer'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module KonnectAPI
          class Base < Liquid::Drop
            BASE_URL = 'https://{us|eu}.api.konghq.com/v2/control-planes/{controlPlaneId}/core-entities'.freeze

            URLS = {
              'consumer'       => "#{BASE_URL}/consumers/",
              'consumer_group' => "#{BASE_URL}/consumer_groups/",
              'route'          => "#{BASE_URL}/routes/",
              'service'        => "#{BASE_URL}/services/",
              'target'         => "#{BASE_URL}/upstreams/{upstreamId}/targets/",
              'upstream'       => "#{BASE_URL}/upstreams/"
            }.freeze

            def initialize(example_drop:)
              @example_drop = example_drop
            end

            def entity_type
              @entity_type ||= @example_drop.entity_type
            end

            def url
              @url ||= Utils::VariableReplacer::URL.run(
                string: self.class::URLS.fetch(entity_type),
                variables: @example_drop.variables
              )
            end

            def data
              @data ||= @example_drop.data
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

            def data
              @example_drop.data.except(*URLS.keys)
            end

            def url
              @url ||= Utils::VariableReplacer::URL.run(
                string: self.class::URLS.fetch(@example_drop.target.key),
                variables: @example_drop.variables
              )
            end
          end
        end
      end
    end
  end
end
