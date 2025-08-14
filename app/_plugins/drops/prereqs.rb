# frozen_string_literal: true

require 'yaml'

module Jekyll
  module Drops
    class Prereqs < Liquid::Drop # rubocop:disable Style/Documentation
      def initialize(page:, site:) # rubocop:disable Lint/MissingSuper
        @page = page
        @site = site
      end

      def [](key)
        key = key.to_s
        if respond_to?(key)
          public_send(key)
        else
          prereqs[key]
        end
      end

      def any?
        # Don't treat the "skip" prereqs as actual prereqs
        filtered_prereqs = prereqs.reject do |k,v|
          next true if k == 'show_works_on' && v == false
          next true if k == 'skip_product' && v == true
        end

        products = @page.data.fetch('products', [])
        products = [] if prereqs['skip_product']

        [tools, filtered_prereqs, products].any?(&:any?)
      end

      def entities?
        prereqs.fetch('entities', []).any?
      end

      def inline
        @inline ||= prereqs.fetch('inline', [])
      end

      def data
        product = @page.data.fetch('products', [])[0]

        # Use KIC rendering for Operator for now
        product = 'kic' if product == 'operator'

        yaml = {}
        yaml = { '_format_version' => '3.0' } if product == 'gateway'

        prereqs.fetch('entities', []).each do |k, files|
          entities = files.map do |f|
            example = @site.data.dig('entity_examples', product, k, f)

            unless example
              raise ArgumentError,
                    "Missing entity_example file in app/_data/entity_examples/#{product}/#{k}/#{f}.{yml,yaml}"
            end

            example
          end
          yaml.merge!(k => entities) if entities
        end

        if product == 'gateway'
          Jekyll::Utils::HashToYAML.new(yaml).convert.gsub("'3.0'", '"3.0"')
        else
          yaml
        end
      end

      def products
        @products ||= @page.data.fetch('products', [])
                           .reject { |p| %w[gateway ai-gateway].include?(p) }
                           .select { |p| File.exist?(product_include_file_path(p)) }
      end

      def tools
        @tools ||= fetch_or_fail(@page, 'tools', [])
      end

      def enterprise
        @min_version ||= @page.data.fetch('min_version', {})
        return @prereqs['enterprise'] unless @min_version['gateway']

        # We implicitly need an enterprise build if the required version >= 3.10
        Gem::Version.new(@min_version['gateway']) >= Gem::Version.new('3.10')
      end

      private

      def prereqs
        @prereqs ||= fetch_or_fail(@page, 'prereqs', {})
      end

      def product_include_file_path(product)
        File.join(@site.source, '_includes', 'prereqs', 'products', "#{product}.md")
      end

      def fetch_or_fail(page, key, default)
        r = page.data.fetch(key, default)
        raise "Prereqs is not a #{default.class} in '#{page.url}'" unless r.is_a?(default.class)

        r
      end
    end
  end
end
