# frozen_string_literal: true

module Jekyll
  module Data
    class Sidebar # rubocop:disable Style/Documentation
      attr_reader :site, :page

      def initialize(site:, page:)
        @site = site
        @page = page
      end

      def process
        return if skip_sidebar?
        return if product.nil? && tool.nil?

        @page.data['index'] = [product, tool].compact.first
      end

      private

      def skip_sidebar?
        @page.data['plugin?'] || @page.data['content_type'] == 'how_to' || @page.data['sidebar'] == false
      end

      def product
        @product ||= @page.data.fetch('products', []).first
      end

      def tool
        @tool ||= @page.data.fetch('tools', []).reject { |t| t == 'operator' }.first
      end
    end
  end
end
