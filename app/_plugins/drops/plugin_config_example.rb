# frozen_string_literal: true

require 'yaml'

module Jekyll
  module Drops
    class PluginConfigExample < Liquid::Drop
      attr_reader :file

      def initialize(file:, plugin:)
        @file   = file
        @plugin = plugin
      end

      def slug
        @slug ||= File.basename(@file, File.extname(@file))
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

      def entity_examples # rubocop:disable Metrics/MethodLength
        @entity_examples ||= @plugin.targets.map do |target|
          EntityExampleBlock::Plugin.new(
            example: {
              'type' => 'plugin',
              'data' => {
                'name' => plugin_slug,
                target => nil,
                'config' => config
              },
              'formats' => formats
            }
          ).to_drop
        end
      end

      def targets
        @targets ||= @plugin.targets
      end

      def formats
        @formats ||= @plugin.formats
      end

      def url
        @url ||= "/plugins/#{@plugin.slug}/examples/#{slug}/"
      end

      private

      def example
        @example ||= YAML.load(File.read(@file))
      end

      def site
        @site ||= Jekyll.sites.first
      end
    end
  end
end
