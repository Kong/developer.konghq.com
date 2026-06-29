# frozen_string_literal: true

require 'yaml'
require_relative './prereqs/product_entities_prereqs'
require_relative './prereqs/product_include_prereqs'
require_relative './prereqs/entity_examples_data'

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

      def default_accordion
        @default_accordion ||= if prereqs['expand_accordion'] == false
                                 ''
                               else
                                 'data-default="0"'
                               end
      end

      def render_works_on?
        return prereqs['show_works_on'] unless prereqs['show_works_on'].nil?
        return false if @page.data.dig('series', 'position').to_i > 1

        true
      end

      def konnect_auth_only?
        @page.data['works_on']&.include?('konnect') && render_works_on? &&
          !(@page.data['products']&.include?('gateway') || @page.data['products']&.include?('ai-gateway'))
      end

      def inline_before
        @inline_before ||= prereqs.fetch('inline', []).select { |i| i['position'] == 'before' }
      end

      def inline_without_position
        @inline_without_position ||= prereqs.fetch('inline', []).reject { |i| i.key?('position') }
      end

      def any?
        # Don't treat the "skip" prereqs as actual prereqs
        filtered_prereqs = prereqs.reject do |k, v|
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

      def entities_product
        @entities_product ||= begin
          product = prereqs['entities_product'] || @page.data.fetch('products', [])[0]
          product = 'kic' if product == 'operator'
          product
        end
      end

      def entities_product_include
        @entities_product_include ||= ProductEntitiesPrereqs.new(
          product: entities_product,
          major: @page.data.dig('major_version', entities_product),
          product_data: @site.data.dig('products', entities_product)
        ).versioned_include
      end

      def data
        product = entities_product

        yaml = {}
        yaml = { '_format_version' => '3.0' } if product == 'gateway'
        yaml.merge!(entity_examples_data(product))

        if product == 'gateway'
          Jekyll::Utils::HashToYAML.new(yaml).convert.gsub("'3.0'", '"3.0"')
        else
          yaml
        end
      end

      def product_includes_map_keys
        @product_includes_map_keys ||= product_includes_map.keys
      end

      def product_includes_map
        @product_includes_map ||= product_includes_prereqs.products_include_map
      end

      def render_gateway_prereq?
        _products = @page.data.fetch('products', [])
        return false unless _products.include?('gateway')
        return true unless _products.include?('ai-gateway')

        major_version = @page.data.dig('major_version', 'ai-gateway')
        major_version && major_version == 1
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

      def product_includes_prereqs
        @product_includes_prereqs ||= ProductIncludePrereqs.new(
          products: @page.data.fetch('products', []),
          major_version: @page.data.fetch('major_version', {}),
          products_data: @site.data.fetch('products', {})
        )
      end

      def entity_examples_data(product)
        EntityExamplesData.new(
          product: product,
          entities: prereqs.fetch('entities', []),
          entity_examples: @site.data.fetch('entity_examples', {}),
          major: @page.data.dig('major_version', product),
          product_data: @site.data.dig('products', product)
        ).to_h
      end

      def prereqs
        @prereqs ||= fetch_or_fail(@page, 'prereqs', {})
      end

      def fetch_or_fail(page, key, default)
        r = page.data.fetch(key, default)
        raise "Prereqs is not a #{default.class} in '#{page.url}'" unless r.is_a?(default.class)

        r
      end
    end
  end
end
