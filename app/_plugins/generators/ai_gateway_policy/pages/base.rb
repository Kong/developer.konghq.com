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
            .merge('schema' => @policy.schema, 'has_overview?' => false)
        end

        def icon
          return unless @policy.icon

          "/assets/icons/plugins/#{@policy.icon}"
        end
      end
    end
  end
end
