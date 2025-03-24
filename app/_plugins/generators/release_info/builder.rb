# frozen_string_literal: true

require_relative '../../lib/site_accessor'

module Jekyll
  module ReleaseInfo
    class Builder # rubocop:disable Style/Documentation
      include Jekyll::SiteAccessor

      def self.run(page)
        new(page).run
      end

      def initialize(page)
        @page = page
      end

      def run
        if product && product == 'api-ops'
          ReleaseInfo::Tool.new(site:, tool:, min_version:, max_version:)
        else
          ReleaseInfo::Product.new(site:, product:, min_version:, max_version:)
        end
      end

      private

      def product
        @product ||= @page.data.fetch('products', []).first
      end

      def tool
        @tool ||= @page.data.fetch('tools', []).first
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
