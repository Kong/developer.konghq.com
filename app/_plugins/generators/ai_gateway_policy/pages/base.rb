# frozen_string_literal: true

require_relative '../../policies/pages/base'

module Jekyll
  module AIGatewayPolicyPages
    module Pages
      class Base # rubocop:disable Style/Documentation
        include Policies::Pages::Base

        def self.base_url
          '/ai-gateway/policies/'
        end

        def breadcrumbs
          @breadcrumbs ||= ['/ai-gateway/', '/ai-gateway/policies/']
        end

        def data
          super
            .merge(
              'schema' => @policy.schema,
              'has_overview?' => !@policy.overview_content.empty?,
              'title' => "#{@policy.metadata['title']} Policy"
            )
            .merge(api_reference_data)
        end

        def icon
          return unless @policy.icon

          "/assets/icons/plugins/#{@policy.icon}"
        end

        private

        def api_reference_data
          return {} unless @policy.api_spec_exists?

          {
            'api_spec_exists?' => true,
            'api_reference_url' => ApiReference.url(@policy)
          }
        end
      end
    end
  end
end
