# frozen_string_literal: true

require 'yaml'

module Jekyll
  module MeshPolicyPages
    module Pages
      class Example < Base # rubocop:disable Style/Documentation
        def url
          @url ||= example.url
        end

        def content
          @content ||= File.read('app/_includes/mesh_policies/example.md')
        end

        def data # rubocop:disable Metrics/MethodLength
          super
            .except('faqs')
            .merge(
              'example?' => true,
              'example' => example,
              'examples' => @policy.examples,
              'content_type' => 'plugin_example',
              'example_title' => example_config['title'],
              'description' => example_config['description'],
              'release' => @policy.latest_release_in_range
            )
        end

        def layout
          'policies/example'
        end

        def example
          @example ||= @policy.examples.detect { |e| e.file == @file }
        end

        private

        def example_config
          @example_config ||= YAML.load(File.read(file))
        end
      end
    end
  end
end
