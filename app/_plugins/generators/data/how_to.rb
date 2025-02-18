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
      end

      def release_info
        @release_info ||= ReleaseInfo::Product.new(
          site:,
          product: @page.data['products'].first,
          min_version: @page.data['min_version'],
          max_version: @page.data['max_version']
        )
      end
    end
  end
end
