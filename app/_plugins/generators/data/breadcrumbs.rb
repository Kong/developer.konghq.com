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
            next build_breadcrumbs_from_static(entry) unless entry['url'].nil?

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

        return normalized_url if ENV['KONG_PRODUCTS']

        unless breadcrumb
          raise ArgumentError,
                "On #{@page.relative_path}, the breadcrumb `#{normalized_url}` is invalid. No page exists with a matching URL." # rubocop:disable Layout/LineLength
        end

        title = breadcrumb.data['title']
        title = breadcrumb.data['short_title'] if breadcrumb.data['short_title']

        { 'url' => normalized_url, 'title' => title }
      end

      def build_breadcrumbs_from_static(entry)
        # We return it as-is for now, but we may process it in the future
        # so I've added a method
        entry
      end

      def build_breadcrumbs_from_index_page(entry)
        unless entry['index']
          raise ArgumentError,
                "On #{@page.relative_path}, the breadcrumb entry `#{entry}` is invalid. It must contain an `index` key."
        end

        slug = Jekyll::Utils.slugify(entry['group'])
        title = entry['group']

        if entry['section']
          slug = "#{slug}--" if entry['group']
          slug = "#{slug}#{Jekyll::Utils.slugify(entry['section'])}"
          title = entry['section']
        end

        { 'url' => "/index/#{entry['index']}/##{slug}", 'title' => title }
      end

      def find_page_by_url(url)
        site.pages.detect { |p| p.url == url } ||
          site.documents.detect { |d| d.url == url }
      end
    end
  end
end
