# frozen_string_literal: true

require_relative '../../policies/pages/reference'
require_relative '../../../file_cache'

module Jekyll
  module EventGatewayPolicyPages
    module Pages
      class Reference < Base
        include Policies::Pages::Reference

        def layout
          'event_gateway_policies/reference'
        end

        def markdown_content
          @markdown_content ||= FileCache.read('app/_includes/event_gateway_policies/reference.md')
        end

        def data
          super.merge('reference_type' => 'base')
        end
      end
    end
  end
end
