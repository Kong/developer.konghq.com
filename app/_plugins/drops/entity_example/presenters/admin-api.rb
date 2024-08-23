# frozen_string_literal: true

require_relative '../utils/variable_replacer'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module AdminAPI
          class Base < Liquid::Drop
            BASE_URL = 'http://localhost:8001'.freeze

            URLS = {
              'consumer'       => "#{BASE_URL}/consumers/",
              'consumer_group' => "#{BASE_URL}/consumer_groups/",
              'route'          => "#{BASE_URL}/routes/",
              'service'        => "#{BASE_URL}/services/"
            }.freeze

            def initialize(example_drop:)
              @example_drop = example_drop
            end

            def url
              @url ||= self.class::URLS.fetch(entity_type)
            end

            def data
              @data ||= @example_drop.data
            end

            def entity_type
              @entity_type ||= @example_drop.entity_type
            end
          end

          class Plugin < Base
            URLS = {
              'consumer'       => "#{BASE_URL}/consumers/{consumerName|Id}/plugins/",
              'consumer_group' => "#{BASE_URL}/consumer_groups/{consumerGroupName|Id}/plugins/",
              'route'          => "#{BASE_URL}/routes/{routeName|Id}/plugins/",
              'service'        => "#{BASE_URL}/services/{serviceName|Id}/plugins/",
              'global'         => "#{BASE_URL}/plugins/"
            }.freeze

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
