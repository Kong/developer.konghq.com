# frozen_string_literal: true

require_relative './base'
require_relative '../../lib/site_accessor'

module Jekyll
  module EntityExampleBlock
    class EventGatewayPolicy < Base
      include Jekyll::SiteAccessor

      def target
        @target ||= if policy_target == 'listener'
                      policy_target
                    else
                      @example['phase']
                    end
      end

      def ordering
        @ordering ||= @example.dig('data', 'ordering')
      end

      def tags
        @tags ||= @example.dig('data', 'tags') || []
      end

      def policy_target
        @policy_target ||= policy.data['policy_target']
      end

      def data
        @data ||= {
          'name' => @example.fetch('name'),
          'type' => @example.fetch('policy_type'),
          'parent_policy_id' => @example['parent_policy_id'],
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

      private

      def policy
        @policy ||= site.data['event_gateway_policies'].fetch(@example.fetch('policy_type'))
      end
    end
  end
end
