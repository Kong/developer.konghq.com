# frozen_string_literal: true

require_relative 'base'

module Jekyll
  module Drops
    module PolicyConfigExample
      class AIGateway < Base
        def product
          'ai-gateway'
        end

        def targets
          @targets ||= if example.key?('scopes')
                         example.fetch('scopes')
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
      end
    end
  end
end
