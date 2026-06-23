# frozen_string_literal: true

require_relative '../../policies/pages/reference'

module Jekyll
  module AIGatewayPolicyPages
    module Pages
      class Reference < Base
        include Policies::Pages::Reference

        MARKDOWN_CONTENT = File.read('app/_includes/plugins/reference.md')

        def layout
          'ai_gateway_policies/reference'
        end

        def markdown_content
          MARKDOWN_CONTENT
        end

        def data
          super.merge('reference_type' => 'base')
        end
      end
    end
  end
end
