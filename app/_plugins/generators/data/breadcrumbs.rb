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
        @page.data['breadcrumbs'].map do |entry|
          next build_breadcrumbs_from_string(entry) if entry.is_a?(String)

          if entry.is_a?(Hash)
            next build_breadcrumbs_from_index_page(entry) unless entry['index'].nil?

            raise ArgumentError,
                  "On #{@page.relative_path}, the breadcrumb entry `#{entry}` is invalid. #{entry.to_json}"
          end

          raise ArgumentError,
                "On #{@page.relative_path}, the breadcrumb entry `#{entry}` is not a string or a hash. #{entry.to_json}"
        end
      end

      def build_breadcrumbs_from_string(url)
        normalized_url = Utils::URL.normalize_path(url)
        breadcrumb = find_page_by_url(normalized_url)

        unless breadcrumb
          raise ArgumentError,
                "On #{@page.relative_path}, the breadcrumb `#{normalized_url}` is invalid. No page exists with a matching URL." # rubocop:disable Layout/LineLength
        end

        { 'url' => normalized_url, 'title' => breadcrumb.data['title'] }
      end

      def build_breadcrumbs_from_index_page(entry)
        unless entry['index']
          raise ArgumentError,
                "On #{@page.relative_path}, the breadcrumb entry `#{entry}` is invalid. It must contain an `index` key."
        end

        slug = Jekyll::Utils.slugify(entry['section'])
        { 'url' => "/index/#{entry['index']}/##{slug}", 'title' => entry['section'] }
      end

      def find_page_by_url(url)
        site.pages.detect { |p| p.url == url } ||
          site.documents.detect { |d| d.url == url }
      end
    end
  end
end
