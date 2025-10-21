# frozen_string_literal: true

require 'yaml'

module Jekyll
  module Drops
    class PluginConfigExample < Liquid::Drop # rubocop:disable Style/Documentation
      class EnvVariable < Liquid::Drop # rubocop:disable Style/Documentation
        def initialize(variable) # rubocop:disable Lint/MissingSuper
          @variable = variable
        end

        def value
          @value ||= @variable.fetch('value').gsub(/^\$/, '')
        end

        def description
          @description ||= @variable['description']
        end
      end

      attr_reader :file, :plugin

      def initialize(file:, plugin:) # rubocop:disable Lint/MissingSuper
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
        @description ||= example.fetch('description')
      end

      def extended_description
        @extended_description ||= example['extended_description']
      end

      def requirements
        @requirements ||= example.fetch('requirements', [])
      end

      def show_in_api?
        example['show_in_api']
      end

      def variables
        @variables ||= example.fetch('variables', {}).map do |k, v|
          EnvVariable.new(v)
        end
      end

      def raw_variables
        @raw_variables ||= example.fetch('variables', {})
      end

      def plugin_slug
        @plugin_slug ||= @plugin.slug
      end

      def title
        @title ||= example.fetch('title')
      end

      def weight
        @weight ||= example.fetch('weight')
      end

      def tags
        @tags ||= example.fetch('tags', [])
      end

      def min_version
        @min_version ||= example['min_version'] || @plugin.send(:min_version)
      end

      def entity_examples # rubocop:disable Metrics/MethodLength
        @entity_examples ||= targets.map do |target|
          EntityExampleBlock::Plugin.new(
            example: {
              'type' => 'plugin',
              'data' => {
                'name' => plugin_slug,
                target => nil,
                'config' => config,
                'tags' => tags,
              },
              'formats' => formats,
              'variables' => example.fetch('variables', {})
            }
          ).to_drop
        end
      end

      def targets
        @targets ||= if example.key?('targets')
                       unless example['targets'].all? { |t| @plugin.targets.include?(t) }
                         raise ArgumentError,
                               "Invalid `targets` in #{@file}, supported targets: #{@plugin.targets.join(', ')}"
                       end
                       example.fetch('targets')
                     else
                       @plugin.targets
                     end
      end

      def formats
        @formats ||= example.fetch('tools')
      end

      def url
        @url ||= if @plugin.unreleased?
                   "/plugins/#{@plugin.slug}/examples/#{slug}/#{@plugin.min_release}"
                 else
                   "/plugins/#{@plugin.slug}/examples/#{slug}/"
                 end
      end

      def id
        @id ||= SecureRandom.hex(10)
      end

      def group
        @group ||= @example['group']
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
