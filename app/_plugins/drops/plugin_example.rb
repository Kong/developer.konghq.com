# frozen_string_literal: true

require 'yaml'

module Jekyll
  module Drops
    class PluginExample < Liquid::Drop
      def initialize(example_file:, plugin:, formats:)
        @example_file = example_file
        @plugin       = plugin
        @formats      = formats
      end

      def slug
        @slug ||= File.basename(@example_file, File.extname(@example_file))
      end

      def config
        @config ||= example.fetch('config', {})
      end

      def description
        @description ||= example.fetch('description', '')
      end

      def plugin_slug
        @plugin_slug ||= @plugin.slug
      end

      def entity_examples
        @entity_examples ||= @plugin.targets.map do |target|
          EntityExampleBlock::Plugin.new(example: {
            'type' => 'plugin',
            'data' => {
              'name'   => plugin_slug,
              target   => nil,
              'config' => config
            },
            'formats' => @formats
          }).to_drop
        end
      end

      def targets
        @targets ||= @plugin.targets
      end

      def formats
        @formats
      end

      private

      def example
        @example ||= YAML.load(File.read(@example_file))
      end

      def site
        @site ||= Jekyll.sites.first
      end
    end
  end
end
