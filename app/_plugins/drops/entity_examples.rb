# frozen_string_literal: true

module Jekyll
  module Drops
    class EntityExamples < Liquid::Drop
      def initialize(config:)
        @config = config
      end

      def entities
        @entities ||= @config.fetch('entities')
      end

      def data
        @data ||= Jekyll::Utils::HashToYAML.new(entities).convert
      end

      def template
        @template ||= File.expand_path('app/_includes/components/entity_examples.html')
      end
    end
  end
end
