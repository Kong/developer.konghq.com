# frozen_string_literal: true

require 'forwardable'

module Jekyll
  module ReferencePages
    class Versioner
      extend Forwardable

      def_delegators :@release_info, :latest_release_in_range, :latest_available_release, :releases,
                     :min_release, :max_release

      attr_reader :page, :site

      def initialize(site:, page:)
        @site = site
        @page = page
        @release_info = release_info
      end

      def process
        set_base_url!
        set_release_info!
        handle_canonicals!
        generate_pages!
      end

      def set_base_url!
        page.data.merge!('base_url' => page.url)
      end

      def set_release_info! # rubocop:disable Metrics/AbcSize
        return if page.data['no_version']

        unless latest_release_in_range
          raise ArgumentError,
                "Missing release for page: #{page.url} in site.data.#{releases_key.join('.')}"
        end

        page.data.merge!(
          'release' => latest_release_in_range,
          'releases' => releases,
          'releases_dropdown' => Drops::ReleasesDropdown.new(base_url: page.url, releases:)
        )
      end

      def handle_canonicals! # rubocop:disable Metrics/AbcSize
        # Setting published: false prevents Jekyll from rendering the page.
        if min_release && min_release > latest_available_release
          page.data.merge!('published' => false)
        elsif max_release && max_release < latest_available_release
          page.data.merge!(
            'published' => false,
            'canonical_url' => "#{page.url}#{max_release}/"
          )
        else
          page.data.merge!('canonical_url' => page.url, 'canonical?' => true)
        end
      end

      def generate_pages!
        return [] if @page.data['no_version']

        releases.map do |release|
          Page.new(site:, page:, release:).to_jekyll_page
        end
      end

      def release_info
        @release_info ||= if product && product == 'api-ops'
                            ReleaseInfo::Tool.new(site:, tool:, min_version:, max_version:)
                          else
                            ReleaseInfo::Product.new(site:, product:, min_version:, max_version:)
                          end
      end

      def product
        @product ||= page.data.fetch('products', []).first
      end

      def tool
        @tool ||= page.data.fetch('tools', []).first
      end

      def min_version
        @min_version ||= @page.data.fetch('min_version', {})
      end

      def max_version
        @max_version ||= @page.data.fetch('max_version', {})
      end
    end
  end
end
