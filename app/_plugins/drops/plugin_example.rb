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

      def targets_dropdown
        options = @plugin.targets.map do |t|
          Drops::Dropdowns::Option.new(text: t, value: t)
        end
        Drops::Dropdowns::Select.new(options)
      end

      def formats_dropdown
        @formats_dropdown ||= begin
          options = @formats.sort.map do |f|
            Jekyll::EntityExampleBlock::Format::Base.make_for(format: f).to_drop
          end
          Drops::Dropdowns::Select.new(
            options.map { |f| Drops::Dropdowns::Option.new(text: f.to_option, value: f.value) }
          )
        end
      end

      private

      def example
        @example ||= YAML.load(File.read(@example_file))
      end
    end
  end
end
