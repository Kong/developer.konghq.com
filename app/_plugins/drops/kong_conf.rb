# frozen_string_literal: true

require 'yaml'

require_relative '../lib/site_accessor'

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

      include Jekyll::SiteAccessor

      def sections
        @sections ||= kong_conf_index.fetch('sections', []).map.with_index do |section, index|
          Section.new(section:, params: section_params(index))
        end
      end

      private

      def kong_conf_index
        @kong_conf_index ||= site.data.dig('kong-conf', 'index')
      end

      def section_params(index)
        kong_conf_index.fetch('params', {}).select do |_k, v|
          v['sectionIndex'] == index
        end
      end
    end
  end
end
