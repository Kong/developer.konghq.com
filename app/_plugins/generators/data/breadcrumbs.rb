# frozen_string_literal: true

module Jekyll
  module Data
    class Breadcrumbs
      attr_reader :site, :page

      def initialize(site:, page:)
        @site = site
        @page = page
      end

      def process
        return unless @page.data['breadcrumbs']

        @page.data['breadcrumbs'] = build_breadcrumbs
      end

      private

      def build_breadcrumbs
        @page.data['breadcrumbs'].map do |url|
          normalized_url = Utils::URL.normalize_path(url)
          breadcrumb = find_page_by_url(normalized_url)
          { 'url' => normalized_url, 'title' => breadcrumb.data['title'] }
        end
      end

      def find_page_by_url(url)
        site.pages.detect { |p| p.url == url } ||
          site.documents.detect { |d| d.url == url }
      end
    end
  end
end
