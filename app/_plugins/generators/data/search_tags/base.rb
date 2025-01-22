# frozen_string_literal: true

module Jekyll
  module Data
    module SearchTags
      class Base # rubocop:disable Style/Documentation
        def self.make_for(site:, page:) # rubocop:disable Metrics/MethodLength
          case page.data['content_type']
          when 'concept'
            Concept.new(site:, page:)
          when 'how_to'
            HowTo.new(site:, page:)
          when 'landing_page'
            LandingPage.new(site:, page:)
          when 'plugin'
            Plugin.new(site:, page:)
          when 'reference'
            Reference.new(site:, page:)
          when nil
            new(site:, page:)
          else
            raise ArgumentError, "Invalid `content_type` for page: #{page.url}"
          end
        end

        def initialize(site:, page:)
          @site = site
          @page = page
        end

        def process
          @page.data['search'] = search_data.compact
        end

        def search_data
          # TODO: breadcrumbs? entities?
          # remove keys that are empty
          {
            'title' => @page.data['title'],
            'description' => @page.data['description'],
            'content_type' => @page.data['content_type'],
            'tier' => @page.data['tier'],
            'products' => @page.data.fetch('products', []).join(','),
            'works_on' => @page.data.fetch('works_on', []).join(','),
            'tools' => @page.data.fetch('tools', []).join(',')
          }
        end
      end
    end
  end
end
