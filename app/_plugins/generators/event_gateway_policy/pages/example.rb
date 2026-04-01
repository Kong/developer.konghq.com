# frozen_string_literal: true

require_relative '../../policies/pages/example'

module Jekyll
  module EventGatewayPolicyPages
    module Pages
      class Example < Base
        include Policies::Pages::Example

        def content
          @content ||= File.read('app/_includes/event_gateway_policies/example.md')
        end
      end
    end
  end
end
