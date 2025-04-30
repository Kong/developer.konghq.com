# frozen_string_literal: true

require_relative 'title/base'

module Jekyll
  module Data
    class TitleTag # rubocop:disable Style/Documentation
      attr_reader :site, :page

      def initialize(site:, page:)
        @site = site
        @page = page
      end

      def process
        return if @page.url.start_with?('/assets/')
        return if @page.data['layout'] && @page.data['layout'] == 'none'
        return if @site.config.dig('sitemap', 'exclude').include?(@page.url)

        set_title_tag
      end

      def set_title_tag
        @page.data['title_tag'] = title
      end

      private

      def title
        return @site.config['title'] if @page.url == '/'

        Title::Base.make_for(page:, site:)
                   .title_sections
                   .uniq
                   .compact
                   .join(' - ')
                   .concat(" | #{@site.config['title']}")
      end

      def feature
        # TODO:
        #   special considerations:
        #     * api pages: - done
        #        * error pages - done
        #        * /api/ => OpenAPI Specifications - done
        #        * /api/name/latest => name - OpenAPI Specification - done
        #        * /api/name/old => name - version - OpenAPI Specification - done
        #     * plugin pages: - done
        #        * add the type of page to the title - done
        #         * configuration, changelog, api - done
        #         * plugin_example? example name - done
        #     * mesh policies - done
        #     * versioned reference pages
        #     * landing pages
        #     * concept pages
        #     * html pages
        #     * else?
        # TODO: same for mesh policies
        return 'Plugin' if @page.url.start_with?('/plugins/')
        return 'OpenAPI Specifications' if @page.url.start_with?('/api/')

        if product
          @site.data.dig('products', product, 'name')
        elsif tool
          @site.data.dig('tools', tool, 'name')
        end
      end
    end
  end
end
