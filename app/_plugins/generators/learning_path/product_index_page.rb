# frozen_string_literal: true

module Jekyll
  module LearningPath
    class ProductIndexPage < Jekyll::Page # rubocop:disable Style/Documentation
      def initialize(site, product, learning_paths) # rubocop:disable Lint/MissingSuper
        @site = site

        # Set self.ext and self.basename
        process('index.md')

        @dir = "#{@site.dest}/learning-paths/#{product}/"

        @content = ''
        @data = {
          'layout' => 'learning-path-index',
          'title' => "#{product_display_name(site, product)} Learning Paths",
          'product' => product,
          'breadcrumbs' => ['/learning-paths/'],
          'learning_paths' => serialize_paths(learning_paths)
        }

        # Synthetic relative_path since this page has no source file on disk.
        @relative_path = "_generated/learning-paths/#{product}/index.md"
      end

      def url
        @url ||= "/learning-paths/#{@data['product']}/"
      end

      private

      def product_display_name(site, product)
        site.data.dig('products', product, 'name') ||
          product.split('-').map(&:capitalize).join(' ')
      end

      def serialize_paths(learning_paths)
        learning_paths.map do |lp|
          {
            'title' => lp.data['title'],
            'description' => lp.data['description'],
            'url' => lp.url,
            'tags' => lp.data['tags'] || [],
            'min_version' => lp.data['min_version']
          }
        end
      end
    end
  end
end
