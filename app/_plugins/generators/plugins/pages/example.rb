# frozen_string_literal: true

require 'yaml'

module Jekyll
  module PluginPages
    module Pages
      class Example < Base # rubocop:disable Style/Documentation
        def url
          @url ||= example.url
        end

        def content
          @content ||= File.read('app/_includes/plugins/example.md')
        end

        def data # rubocop:disable Metrics/MethodLength
          super
            .except('faqs')
            .merge(
              'example?' => true,
              'example' => example,
              'examples' => @plugin.examples,
              'content_type' => 'plugin_example',
              'no_version' => true,
              'example_title' => example_config['title'],
              'description' => example_config['description']
            )
        end

        def layout
          'plugins/example'
        end

        def example
          @example ||= @plugin.examples.detect { |e| e.file == @file }
        end

        private

        def example_config
          @example_config ||= YAML.load(File.read(file))
        end
      end
    end
  end
end
