# frozen_string_literal: true

module Jekyll
  module AIGatewayPluginPages
    module Pages
      class Reference < Base
        def self.url(plugin)
          "/ai-gateway/on-prem/plugins/#{plugin.slug}/reference/"
        end

        def content
          ''
        end

        def layout
          'ai_gateway_policies/reference'
        end

        def data
          super
            .except('faqs')
            .merge(
              'content_type' => 'reference',
              'reference?'   => true,
              'toc'          => false,
              'versioned'    => false
            )
        end
      end
    end
  end
end
