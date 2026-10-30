# frozen_string_literal: true

require_relative 'base'

module Jekyll
  module Drops
    module PolicyConfigExample
      class AIGateway < Base
        TOOLS = %w[konnect-api terraform kongctl].freeze

        def initialize(file:, plugin:)
          super
          validate!
        end

        def product
          'ai-gateway'
        end

        def examples
          @examples ||= targets.map do |target|
            EntityExample::AIGatewayPolicy.new(example: self, target:)
          end
        end

        def targets
          @targets ||= if example.key?('scopes')
                         validate_scopes(example.fetch('scopes'))
                       else
                         @plugin.scopes
                       end
        end

        def data
          @data ||= {
            'name' => example.fetch('name'),
            'display_name' => example.fetch('display_name'),
            'type' => example.fetch('type'),
            'enabled' => example.fetch('enabled', true),
            'condition' => example['condition']&.chomp,
            'config' => config
          }.compact
        end

        private

        def validate!
          raise ArgumentError, "Invalid `global` in #{@file}: the target sets `global`, remove the `global` key" if example.key?('global')
          raise ArgumentError, "Missing `display_name` in #{@file}" if example['display_name'].nil?

          invalid_tools = example.fetch('tools') - TOOLS
          raise ArgumentError, "Invalid `tools` in #{@file}, supported tools: #{TOOLS.join(', ')}" unless invalid_tools.empty?

          targets
        end

        def validate_scopes(subset)
          unsupported = subset - @plugin.scopes
          return subset if unsupported.empty?

          raise ArgumentError, "Invalid `scopes` in #{@file}, supported scopes: #{@plugin.scopes.join(', ')}"
        end
      end
    end
  end
end
