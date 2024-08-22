# frozen_string_literal: true

module Jekyll
  module Drops
    class EntityExamples < Liquid::Drop
      def initialize(config:)
        @config = config

        validate!
      end

      def entities
        @entities ||= @config.fetch('entities')
      end

      def append_to_existing_section
        @config['append_to_existing_section']
      end

      def append_to
        @append_to ||= entities.keys.first
      end

      def data
        @data ||= if append_to_existing_section
                    Jekyll::Utils::HashToYAML.new(entities[append_to]).convert
                  else
                    Jekyll::Utils::HashToYAML.new(entities).convert
                  end
      end

      def template
        @template ||= File.expand_path('app/_includes/components/entity_examples.html')
      end

      private

      def validate!
        if append_to_existing_section && entities.size > 1
          raise ArgumentError, "Invalid config for entity_examples. If `append_to_existing_section` is set, only one type of entity can be specified."
        end
      end
    end
  end
end
