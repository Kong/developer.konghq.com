# frozen_string_literal: true

require_relative '../policies/generator'
require_relative '../policies/generator_base'

module Jekyll
  module EventGatewayPolicyPages
    class Generator # rubocop:disable Style/Documentation
      include Policies::Generator
      include Policies::GeneratorBase

      def self.policies_folder
        '_event_gateway_policies'
      end

      def key
        @key ||= 'event_gateway_policies'
      end

      def skip?
        site.config.dig('skip', 'event_gateway_policy')
      end
    end
  end
end
