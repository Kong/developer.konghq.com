# frozen_string_literal: true

require_relative '../../policies/pages/example'
require_relative '../../../file_cache'

module Jekyll
  module AIGatewayPolicyPages
    module Pages
      class Example < Base
        include Policies::Pages::Example

        def content
          @content ||= FileCache.read('app/_includes/ai_gateway_policies/example.md')
        end
      end
    end
  end
end
