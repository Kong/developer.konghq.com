# frozen_string_literal: true

require_relative '../../policies/pages/overview'

module Jekyll
  module EventGatewayPolicyPages
    module Pages
      class Overview < Base
        include Policies::Pages::Overview

        def data
          super.merge(
            'phases' => @policy.phases || [],
            'policy_target' => @policy.policy_target
          )
        end
      end
    end
  end
end
