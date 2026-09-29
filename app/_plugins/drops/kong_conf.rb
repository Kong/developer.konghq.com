# frozen_string_literal: true

require 'json'

module Jekyll
  module Drops
    class KongConf < Liquid::Drop # rubocop:disable Style/Documentation
      class Section < Liquid::Drop # rubocop:disable Style/Documentation
        def initialize(section:, params:) # rubocop:disable Lint/MissingSuper
          @section = section
          @params = params
        end

        def title
          @title ||= @section['title']
        end

        def description
          @description ||= @section['description']
        end

        def parameters
          @parameters ||= @params.map do |k, v|
            { 'name' => k }.merge(v)
          end
        end
      end

      KONG_CONF_INDICES = %w[gateway ai-gateway].each_with_object({}) do |product, h|
        path = File.expand_path("../../_kong-conf/#{product}/index.json", __dir__)
        h[product] = JSON.parse(File.read(path)) if File.exist?(path)
      end.freeze

      def initialize(product = 'gateway') # rubocop:disable Lint/MissingSuper
        @product = product
      end

      def sections
        @sections ||= index.fetch('sections', []).map do |section|
          Section.new(section:, params: section_params(section))
        end
      end

      attr_reader :product

      private

      def index
        KONG_CONF_INDICES.fetch(@product, {})
      end

      def section_params(section)
        index.fetch('params', {}).select do |_k, v|
          v['sectionTitle'] == section['title']
        end
      end
    end
  end
end
