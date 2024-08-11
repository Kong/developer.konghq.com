# frozen_string_literal: true

require 'yaml'
require_relative '../utils/variable_replacer'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module Deck
          class Base < Liquid::Drop
            def initialize(target:, data:, entity_type:, variables:)
              @target      = target
              @data        = data
              @entity_type = entity_type
              @variables   = variables
            end

            def entity
              @entity ||= "#{@entity_type}s"
            end

            def data
              Jekyll::Utils::HashToYAML.new(
                { entity => [ @data ] }
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
              plugin = { 'name' => @data.fetch('name') }
              plugin.merge!(@target => target) if @target != 'global'
              plugin.merge!('config' => @data.fetch('config'))

              Jekyll::Utils::HashToYAML.new({ 'plugins' => [plugin] }).convert
            end

            def target
              return unless TARGETS.fetch(@target)

              Utils::VariableReplacer::Text.run(
                string: TARGETS.fetch(@target),
                variables: @variables
              )
            end
          end
        end
      end
    end
  end
end
