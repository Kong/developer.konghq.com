# frozen_string_literal: true

module Jekyll
  module Data
    class MinVersion # rubocop:disable Style/Documentation
      attr_reader :site, :page

      def initialize(site:, page:)
        @site = site
        @page = page
      end

      def process # rubocop:disable Metrics/AbcSize
        return unless %w[how_to landing_page].include?(@page.data['content_type'])
        return unless @page.data['min_version']

        @page.data['latest_release'] = release_info.latest_available_release
        return unless unreleased?

        @page.instance_variable_set(:@url, "#{@page.url}#{release_info.min_release}/")

        return unless ENV['JEKYLL_ENV'] == 'production'

        @page.data['published'] = false
      end

      def release_info
        @release_info ||= ReleaseInfo::Builder.run(@page)
      end

      def unreleased?
        @release_info.unreleased?
      end
    end
  end
end
