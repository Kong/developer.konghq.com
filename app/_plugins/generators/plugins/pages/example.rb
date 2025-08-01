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
              'basic_examples' => @plugin.basic_examples,
              'examples_by_group' => @plugin.examples_by_group,
              'min_version' => example.min_version,
              'content_type' => 'plugin_example',
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
