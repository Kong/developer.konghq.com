# frozen_string_literal: true

require_relative './entity_example/utils/variable_replacer'

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
        @data ||= EntityExample::Utils::VariableReplacer::DeckData.run(
          data: Jekyll::Utils::HashToYAML.new(entities).convert,
          variables: variables
        )
      end

      def template
        @template ||= File.expand_path('app/_includes/components/entity_examples.html')
      end

      def variables
        @variables ||= @config.fetch('variables', {})
      end
    end
  end
end
