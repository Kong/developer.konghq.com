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

        set_titles
      end

      def set_titles
        @page.data['title_tag'] = title_tag
        @page.data['llm_title'] = llm_title
      end

      private

      def title_tag
        return @site.config['title'] if @page.url == '/'

        title
          .title_sections
          .uniq
          .compact
          .join(' - ')
          .concat(" | #{@site.config['title']}")
      end

      def llm_title
        return @site.config['title'] if @page.url == '/'

        title.llm_title
      end

      def title
        @title ||= Title::Base.make_for(page:, site:)
      end
    end
  end
end
