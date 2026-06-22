# frozen_string_literal: true

require_relative '../policies/base'

module Jekyll
  module AIGatewayPolicyPages
    class Policy # rubocop:disable Style/Documentation
      include Policies::Base
      include Policies::GeneratorBase

      def schema
        # delegate to the plugin schema
        @schema ||= { 'properties' => { 'config' => api_plugin.data['schema'].as_json.dig('properties',
                                                                                          'config') } } || {}
      end

      def examples
        @examples ||= []
      end

      def metadata
        @metadata ||= api_plugin
                      .data['plugin']
                      .metadata.slice(*policies_metadata.fetch('keep'))
                      .merge('schema' => schema)
                      .merge(super)
      end

      private

      def api_plugin
        @api_plugin ||= site.data['kong_plugins'].fetch(@slug)
      end

      def policies_metadata
        @policies_metadata ||= site.config.dig('ai_gateway_policies', 'metadata')
      end
    end
  end
end
