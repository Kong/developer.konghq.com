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

      KONG_CONF_INDEX = JSON.parse(File.read(File.expand_path('../../_kong-conf/index.json', __dir__)))

      def sections
        @sections ||= KONG_CONF_INDEX.fetch('sections', []).map do |section|
          Section.new(section:, params: section_params(section))
        end
      end

      private

      def section_params(section)
        KONG_CONF_INDEX.fetch('params', {}).select do |_k, v|
          v['sectionTitle'] == section['title']
        end
      end
    end
  end
end
