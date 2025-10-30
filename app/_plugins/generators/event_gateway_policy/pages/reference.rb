# frozen_string_literal: true

require_relative '../../policies/pages/reference'

module Jekyll
  module EventGatewayPolicyPages
    module Pages
      class Reference < Base
        include Policies::Pages::Reference

        def layout
          'event_gateway_policies/reference'
        end

        def data
          super.merge('reference_type' => 'base')
        end
      end
    end
  end
end
