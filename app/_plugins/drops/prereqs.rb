# frozen_string_literal: true

require 'yaml'

module Jekyll
  module Drops
    class Prereqs < Liquid::Drop
      def initialize(prereqs:, tools:, site:)
        @prereqs = prereqs
        @tools   = tools
        @site    = site
      end

      def any?
        @tools.any? || @prereqs.any?
      end

      def tools
        @tools
      end

      def entities?
        @prereqs.fetch('entities', []).any?
      end

      def inline
        @inlines ||= @prereqs.fetch('inline', [])
      end

      def data
        yaml = { '_format_version' => '3.0' }

        @prereqs.fetch('entities', []).each do |k, files|
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
    end
  end
end
