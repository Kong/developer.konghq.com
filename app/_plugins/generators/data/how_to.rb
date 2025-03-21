# frozen_string_literal: true

module Jekyll
  module Data
    class HowTo
      attr_reader :site, :page

      def initialize(site:, page:)
        @site = site
        @page = page
      end

      def process
        @page.data['latest_release'] = release_info.latest_available_release
        return unless unreleased?

        @page.instance_variable_set(:@url, "#{@page.url}/#{release_info.min_release}/")

        return unless ENV['JEKYLL_ENV'] == 'production'

        @page.data['published'] = false
      end

      def release_info
        @release_info ||= ReleaseInfo::Product.new(
          site:,
          product: @page.data['products'].first,
          min_version: @page.data.fetch('min_version', {}),
          max_version: @page.data.fetch('max_version', {})
        )
      end

      def unreleased?
        return false unless @page.data['min_version']

        @release_info.unreleased?
      end
    end
  end
end
