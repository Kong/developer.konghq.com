# frozen_string_literal: true

module Jekyll
  module Data
    class AddAllDocIndices # rubocop:disable Style/Documentation
      attr_reader :site, :page

      def initialize(site:, page:)
        @site = site
        @page = page
      end

      def process
        return if product.nil? && tools.empty?

        @page.data['all_docs_indices'] = [product_index, tool_index].compact.map do |index|
          build_index_link(index)
        end.uniq
      end

      def build_index_link(index)
        { 'text' => index.data['title'], 'url' => index.url, 'slug' => index.data['slug'] }
      end

      def product_index
        return unless product

        @site.data.dig('indices', product)
      end

      def tool_index
        return if tools.empty? || tools.size > 1

        @site.data.dig('indices', tools.first)
      end

      private

      def product
        @product ||= product_expanded(@page.data.fetch('products', []).first)
      end

      def tools
        @tools ||= @page.data.fetch('tools', []).reject { |t| t == 'operator' }
      end

      def product_expanded(product)
        product
      end
    end
  end
end
