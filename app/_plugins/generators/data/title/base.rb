# frozen_string_literal: true

module Jekyll
  module Data
    module Title
      class Base # rubocop:disable Style/Documentation
        def self.make_for(page:, site:) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
          if page.url.start_with?('/api/')
            APIPage.new(page:, site:)
          elsif page.url.start_with?('/plugins/')
            Plugin.new(page:, site:)
          elsif page.url.start_with?('/mesh/policies/') || page.url.start_with?('/event-gateway/policies/')
            Policy.new(page:, site:)
          elsif page.data['content_type'] && page.data['content_type'] == 'reference'
            Reference.new(page:, site:)
          elsif page.data['content_type'] && page.data['content_type'] == 'how_to'
            HowTo.new(page:, site:)
          else
            # for plain html pages or pages that don't require anything specific
            OpenStruct.new(title_sections: [page.data['title']])
          end
        end

        def initialize(page:, site:)
          @page = page
          @site = site
        end

        private

        def page_title
          @page_title ||= @page.data['title']
        end

        def product
          @product ||= @page.data.fetch('products', []).first
        end

        def tool
          @tool ||= @page.data.fetch('tools', []).first
        end
      end
    end
  end
end
