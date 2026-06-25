# frozen_string_literal: true

require_relative '../policies/generator'
require_relative '../policies/generator_base'

module Jekyll
  module AIGatewayPolicyPages
    class Generator # rubocop:disable Style/Documentation
      include Policies::Generator
      include Policies::GeneratorBase

      def self.policies_folder
        '_ai_gateway_policies'
      end

      def key
        @key ||= 'ai_gateway_policies'
      end

      def skip?
        site.config.dig('skip', 'ai_gateway_policy')
      end

      # TODO: for now, until we have overviews and examples
      def generate_pages(policy)
        reference = generate_reference_page(policy)

        site.data[key][policy.slug] = reference
      end
    end
  end
end
