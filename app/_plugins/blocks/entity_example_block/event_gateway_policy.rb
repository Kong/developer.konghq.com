# frozen_string_literal: true

require_relative './base'

module Jekyll
  module EntityExampleBlock
    class EventGatewayPolicy < Base
      def target
        @target ||= @example['target']
      end

      def ordering
        @ordering ||= @example.dig('data', 'ordering')
      end

      def tags
        @tags ||= @example.dig('data', 'tags') || []
      end

      def policy_target
        @policy_target ||= @example['target']
      end

      def data
        @data ||= {
          'name' => @example.fetch('name'),
          'type' => @example.fetch('policy_type'),
          'condition' => @example['condition']&.chomp,
          'config' => @example.fetch('data')
        }.compact
      end

      def raw_variables
        @raw_variables ||= example.fetch('variables', {})
      end

      def options
        super.merge({ target: target })
      end
    end
  end
end
