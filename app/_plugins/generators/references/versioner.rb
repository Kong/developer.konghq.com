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
        page.data['release'] = latest_release

        releases.reject(&:latest?).map do |release|
          Page.new(site:, page:, release:).to_jekyll_page
        end
      end

      private

      def product
        @product ||= page.data['products'].first
      end

      def releases
        @releases ||= if product == 'api-ops'
          site.data.dig('tools', page.data['tools'].first, 'releases') || []
        else
          site.data.dig('products', product, 'releases') || []
        end.map { |r| Drops::Release.new(r) }
      end

      def latest_release
        @latest_release ||= releases.detect(&:latest?)
      end
    end
  end
end