# frozen_string_literal: true

require 'forwardable'

module Jekyll
  module ReferencePages
    class Versioner
      extend Forwardable

      def_delegators :@release_info, :latest_release_in_range, :latest_available_release, :releases,
                     :deduplicated_releases, :use_release_name?, :min_release, :max_release

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
        if page.data['versioned'] && !latest_release_in_range
          raise ArgumentError, "Missing release for page: #{page.url}"
        end

        page.data.merge!(
          'release' => latest_release_in_range,
          'releases' => deduplicated_releases,
          'releases_dropdown' => Drops::ReleasesDropdown.new(
            base_url: page.url, releases: deduplicated_releases,
            use_name: use_release_name?
          )
        )
      end

      def handle_canonicals!
        page.data.merge!(CanonicalPolicy.for(page:, release_info: @release_info).to_h)
      end

      def generate_pages! # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
        return [] if page.data['plugin?'] && page.data['changelog?']

        unless page.data['versioned']
          return [] unless min_release && min_release > latest_available_release
          return [] if ENV['JEKYLL_ENV'] == 'production'
        end

        deduplicated_releases.map do |release|
          Page::Base.make_for(site:, page:, release:).to_jekyll_page
        end
      end

      def release_info
        @release_info ||= ReleaseInfo::Builder.run(@page)
      end
    end
  end
end
