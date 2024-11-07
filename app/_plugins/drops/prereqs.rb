# frozen_string_literal: true

require 'yaml'

module Jekyll
  module Drops
    class Prereqs < Liquid::Drop
      def initialize(page:, site:)
        @page = page
        @site = site
      end

      def any?
        [tools, prereqs, products].any?(&:any?)
      end

      def entities?
        prereqs.fetch('entities', []).any?
      end

      def inline
        @inline ||= prereqs.fetch('inline', [])
      end

      def data
        yaml = { '_format_version' => '3.0' }

        prereqs.fetch('entities', []).each do |k, files|
          entities = files.map do |f|
            example = @site.data.dig('entity_examples', k, f)

            unless example
              raise ArgumentError, "Missing entity_example file in app/_data/entity_examples/#{k}/#{f}.{yml,yaml}"
            end

            example
          end
          yaml.merge!(k => entities) if entities
        end

        Jekyll::Utils::HashToYAML.new(yaml).convert
      end

      def products
        @products ||= @page.data.fetch('products', [])
          .reject { |p| p == 'gateway' }
          .select { |p| File.exist?(product_include_file_path(p)) }
      end

      def tools
        @tools ||= @page.data.fetch('tools', [])
      end

      private

      def prereqs
        @prereqs ||= @page.data.fetch('prereqs', {})
      end

      def product_include_file_path(product)
        File.join(@site.source, '_includes', 'prereqs', 'products', "#{product}.md")
      end
    end
  end
end