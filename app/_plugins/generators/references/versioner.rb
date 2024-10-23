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
        set_release_info!
        handle_canonicals!
        generate_pages!
      end

      def set_release_info!
        raise ArgumentError, "Missing release for page: #{page.url} in site.data.#{releases_key.join('.')}" unless latest_release_in_range

        page.data.merge!(
          'base_url'          => page.url,
          'latest?'           => latest_release_in_range == latest_available_release,
          'release'           => latest_release_in_range,
          'releases'          => releases,
          'releases_dropdown' => Drops::ReleasesDropdown.new(base_url: page.url, releases:)
        )
      end

      def handle_canonicals!
        # Setting published: false prevents Jekyll from rendering the page.
        if min_version && min_version > latest_available_release
          page.data.merge!('published' => false)
        elsif max_version && max_version < latest_available_release
          page.data.merge!(
            'published'     => false,
            'canonical_url' => "#{page.url}#{max_version}/"
          )
        else
          page.data.merge!('canonical_url' => page.url)
        end
      end

      def generate_pages!
        releases.map do |release|
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
        @available_releases ||= (site.data.dig(*releases_key, 'releases') || [])
          .map { |r| Drops::Release.new(r) }
      end

      def releases_key
        @releases_key ||= if product == 'api-ops'
          ['tools', page.data['tools'].first]
        else
          ['products', product]
        end
      end

      def latest_available_release
        @latest_available_release ||= available_releases.detect(&:latest?)
      end

      def latest_release_in_range
        @latest_release_in_range ||= begin
          return min_version if min_version && min_version > latest_available_release
          return max_version if max_version && max_version < latest_available_release

          latest_available_release
        end
      end
    end
  end
end