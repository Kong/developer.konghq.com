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
        generate_overview_page(policy) unless policy.overview_content.empty?

        reference = generate_reference_page(policy)
        generate_api_reference_page(policy)

        site.data[key][policy.slug] ||= reference
      end

      def generate_api_reference_page(policy)
        return unless policy.api_spec_exists?

        api_reference = api_reference_page_class
                        .new(policy:, file: policy.api_spec_file_path)
                        .to_jekyll_page

        site.pages << api_reference
      end

      def skip_locally?
        @build_filter.excludes_prefix?('/ai-gateway/')
      end
    end
  end
end
