# frozen_string_literal: true

module Jekyll
  module ReferencePages
    class Versioner
      attr_reader :page, :site

      def initialize(site:, page:)
        @site = site
        @page = page
      end

      def process
        page.data['release'] = canonical_release

        releases.reject{ |r| r == canonical_release }.map do |release|
          Page.new(site:, page:, release:).to_jekyll_page
        end
      end

      private

      def product
        @product ||= page.data['products'].first
      end

      def min_version
        @min_version ||= begin
          min_version = version_range('min_version')
          min_version && available_releases.detect { |r| r['release'] == min_version }
        end
      end

      def max_version
        @max_version ||= begin
          max_version = version_range('max_version')
          max_version && available_releases.detect { |r| r['release'] == max_version }
        end
      end

      def version_range(version_type)
        if product == 'api-ops'
          page.data.dig(version_type, page.data['tools'].first)
        else
          page.data.dig(version_type, product)
        end
      end

      def releases
        @releases ||= available_releases.select do |r|
          Utils::Version.in_range?(r['release'], min: min_version, max: max_version)
        end
      end

      def available_releases
        @available_releases ||= if product == 'api-ops'
          site.data.dig('tools', page.data['tools'].first, 'releases') || []
        else
          site.data.dig('products', product, 'releases') || []
        end.map { |r| Drops::Release.new(r) }
      end

      def latest_release
        @latest_release ||= available_releases.detect(&:latest?)
      end

      def canonical_release
        @canonical_release ||= begin
          return min_version if min_version && min_version > latest_release
          return max_version if max_version && max_version < latest_release

          latest_release
        end
      end
    end
  end
end