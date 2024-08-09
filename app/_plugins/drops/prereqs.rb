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
        services.any? || routes.any? || consumers.any? || plugins.any?
      end

      def data
        yaml = {
          '_format_version' => '3.0',
        }
        yaml.merge!('services' => services) if services.any?
        yaml.merge!('routes' => routes) if routes.any?
        yaml.merge!('consumers' => consumers) if consumers.any?
        yaml.merge!('plugins' => plugins) if plugins.any?

        Jekyll::Utils::HashToYAML.new(yaml).convert
      end

      def services
        @services ||= @prereqs.fetch('services', []).map do |s|
          load_yaml(find_file(folder: 'services', example: s))
        end
      end

      def routes
        @routes ||= @prereqs.fetch('routes', []).map do |r|
          load_yaml(find_file(folder: 'routes', example: r))
        end
      end

      def consumers
        @consumers ||= @prereqs.fetch('consumers', []).map do |c|
          load_yaml(find_file(folder: 'consumers', example: c))
        end
      end

      def plugins
        @plugins ||= @prereqs.fetch('plugins', []).map do |p|
          load_yaml(find_file(folder: 'plugins', example: p))
        end
      end

      private

      def find_file(folder:, example:)
        file = "#{EXAMPLES_FOLDER}/#{folder}/#{example}.yml"
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
