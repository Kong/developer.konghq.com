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
    end
  end
end
