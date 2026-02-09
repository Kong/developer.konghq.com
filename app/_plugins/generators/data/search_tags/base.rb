# frozen_string_literal: true

module Jekyll
  module Data
    module SearchTags
      class Base # rubocop:disable Style/Documentation
        MAPPINGS = {
          'api' => 'API',
          'concept' => 'Concept',
          'how_to' => 'HowTo',
          'landing_page' => 'LandingPage',
          'plugin' => 'Plugin',
          'plugin_example' => 'PluginExample',
          'reference' => 'Reference',
          'policy' => 'Policy',
          'support' => 'Support'
        }.freeze

        def self.make_for(site:, page:)
          klass = MAPPINGS[page.data['content_type']]

          if klass
            Object.const_get("Jekyll::Data::SearchTags::#{klass}").new(site:, page:)
          elsif page.data['content_type'].nil?
            new(site:, page:)
          else
            raise ArgumentError, "Invalid `content_type`: #{page.data['content_type']} for page: #{page.url}"
          end
        end

        def initialize(site:, page:)
          @site = site
          @page = page
        end

        def process
          @page.data['search'] = search_data.compact
        end

        def search_data # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          data = {
            'title' => @page.data['title'],
            'description' => @page.data['description'],
            'content_type' => @page.data['content_type']
          }

          data.merge!('tier' => tier) if tier
          data.merge!('products' => products) if products
          data.merge!('works_on' => works_on) if works_on
          data.merge!('tags' => tags) if tags
          data.merge!('tools' => tools) if tools
          data.merge!('search_aliases' => search_aliases) if search_aliases

          data
        end

        private

        def products
          return unless @page.data['products']

          @page.data.fetch('products', []).join(',')
        end

        def works_on
          return unless @page.data['works_on']

          @page.data.fetch('works_on', []).join(',')
        end

        def tools
          return unless @page.data['tools']

          @page.data.fetch('tools', []).join(',')
        end

        def tags
          return unless @page.data['tags']

          @page.data.fetch('tags', []).join(',')
        end

        def tier
          return unless @page.data['tier']
          return unless @page.data['products']

          @page.data['tier']
        end

        def search_aliases
          return unless @page.data['search_aliases']

          @page.data.fetch('search_aliases', []).join(',')
        end
      end
    end
  end
end
