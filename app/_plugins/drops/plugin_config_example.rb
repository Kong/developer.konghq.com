# frozen_string_literal: true

require_relative './config_example/base'

module Jekyll
  module Drops
    class PluginConfigExample < Liquid::Drop # rubocop:disable Style/Documentation
      include ConfigExample::Base

      def plugin_slug
        @plugin_slug ||= @plugin.slug
      end

      def show_in_api?
        example['show_in_api']
      end

      def tags
        @tags ||= example.fetch('tags', [])
      end

      def examples # rubocop:disable Metrics/MethodLength
        @examples ||= targets.map do |target|
          EntityExampleBlock::Plugin.new(
            example: {
              'type' => 'plugin',
              'data' => {
                'name' => plugin_slug,
                target => nil,
                'config' => config,
                'tags' => tags
              },
              'formats' => formats,
              'variables' => example.fetch('variables', {})
            },
            product: 'gateway'
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

      def url
        @url ||= if @plugin.unreleased?
                   "/plugins/#{@plugin.slug}/examples/#{slug}/#{@plugin.min_release}"
                 else
                   "/plugins/#{@plugin.slug}/examples/#{slug}/"
                 end
      end
    end
  end
end
