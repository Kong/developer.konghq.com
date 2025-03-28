# frozen_string_literal: true

module Jekyll
  module Data
    class AddIndexToRelatedResources # rubocop:disable Style/Documentation
      attr_reader :site, :page

      def initialize(site:, page:)
        @site = site
        @page = page
      end

      def process
        return if @page.data['content_type'] == 'landing_page'
        return if product.nil? && tool.nil?
        return unless documentation_index

        if @page.data.key?('related_resources')
          @page.data['related_resources'].unshift(index_related_resource)
        else
          @page.data['related_resources'] = [index_related_resource]
        end
      end

      def index_related_resource
        { 'text' => documentation_index.data['title'], 'url' => documentation_index.url }
      end

      private

      def documentation_index
        if product
          key = product == 'api-ops' ? tool : product
          @site.data.dig('indices', key)
        else
          @site.data.dig('indices', tool)
        end
      end

      def product
        @product ||= @page.data.fetch('products', []).first
      end

      def tool
        @tool ||= @page.data.fetch('tools', []).first
      end
    end
  end
end
