# frozen_string_literal: true

require 'yaml'
require_relative '../utils/variable_replacer'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module Deck
          class Base < Liquid::Drop
            def initialize(example_drop:)
              @example_drop = example_drop
            end

            def entity
              @entity ||= "#{@example_drop.entity_type}s"
            end

            def data
              @data ||= @example_drop.data
            end

            def config
              @config ||= Jekyll::Utils::HashToYAML.new(
                { entity => [ data ] }
              ).convert
            end
          end

          class Plugin < Base
            TARGETS = {
              'consumer'       => 'consumerName|Id',
              'consumer_group' => 'consumerGroupName|Id',
              'global'         => nil,
              'route'          => 'routeName|Id',
              'service'        => 'serviceName|Id'
            }.freeze

            def data
              plugin = { 'name' => @example_drop.data.fetch('name') }
              plugin.merge!(target.key => target.value) if target.key != 'global'
              plugin.merge!('config' => @example_drop.data.fetch('config'))

              Jekyll::Utils::HashToYAML.new({ 'plugins' => [plugin] }).convert
            end

            def target
              @target ||= @example_drop.target
            end
          end
        end
      end
    end
  end
end
