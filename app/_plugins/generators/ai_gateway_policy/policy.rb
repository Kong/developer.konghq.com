# frozen_string_literal: true

require_relative '../policies/base'
require_relative '../../drops/plugins/aigw_policy_schema'

module Jekyll
  module AIGatewayPolicyPages
    class Policy # rubocop:disable Style/Documentation
      include Policies::Base
      include Policies::GeneratorBase

      def schema
        @schema ||= Jekyll::Drops::Plugins::AIGWPolicySchema.new(slug: @slug)
      end

      def examples
        @examples ||= []
      end

      def metadata
        @metadata ||= api_plugin
                      .data['plugin']
                      .metadata.slice(*policies_metadata.fetch('keep'))
                      .merge('schema' => schema, 'scopes' => scopes)
                      .merge(super)
      end

      private

      def api_plugin
        @api_plugin ||= site.data['kong_plugins'].fetch(@slug)
      end

      def policies_metadata
        @policies_metadata ||= site.config.dig('ai_gateway_policies', 'metadata')
      end

      def scopes
        @scopes ||= site.data.dig('policies', 'ai-gateway', 'scopes')
                        &.find { |entry| entry['name'] == @slug }
                        &.fetch('scopes', [])
                        &.map { |s| normalize_scope(s) } || []
      end

      def normalize_scope(scope)
        return scope if scope == 'global'

        "ai-#{scope.chomp('s')}"
      end
    end
  end
end
