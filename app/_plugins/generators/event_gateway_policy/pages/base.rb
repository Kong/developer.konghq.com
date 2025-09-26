# frozen_string_literal: true

require_relative '../../policies/pages/base'

module Jekyll
  module EventGatewayPolicyPages
    module Pages
      class Base # rubocop:disable Style/Documentation
        include Policies::Pages::Base

        def self.base_url
          '/event-gateway/policies/'
        end

        def breadcrumbs
          @breadcrumbs ||= ['/event-gateway/', '/event-gateway/policies/']
        end

        def icon
          return unless @policy.icon

          "/assets/icons/event_gateway_policies/#{@policy.icon}"
        end
      end
    end
  end
end
