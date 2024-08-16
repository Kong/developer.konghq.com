# frozen_string_literal: true

require 'yaml'

module Jekyll
  module Drops
    class Prereqs < Liquid::Drop
      EXAMPLES_FOLDER = 'app/_data/entity_examples/'.freeze

      def initialize(prereqs:, tools:)
        @prereqs = prereqs
        @tools   = tools
      end

      def any?
        @tools.any? || @prereqs.any?
      end

      def tools
        @tools
      end

      def entities?
        @prereqs.any?
      end

      def data
        yaml = { '_format_version' => '3.0' }

        @prereqs.each do |k, files|
          entities = files.map { |f| load_yaml(find_file(folder: k, example: f)) }
          yaml.merge!(k => entities) if entities
        end

        Jekyll::Utils::HashToYAML.new(yaml).convert
      end

      private

      def find_file(folder:, example:)
        file = File.join(EXAMPLES_FOLDER, folder, "#{example}.yml")
        unless File.exist?(file)
          raise ArgumentError, "Missing example file: #{file}"
        end
        file
      end

      def load_yaml(file)
        YAML.load(File.read(file))
      end
    end
  end
end
