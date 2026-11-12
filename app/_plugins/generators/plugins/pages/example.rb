# frozen_string_literal: true

require 'yaml'
require_relative '../../../file_cache'
require_relative '../../../drops/plugin_credential_example'

module Jekyll
  module PluginPages
    module Pages
      class Example < Base # rubocop:disable Style/Documentation
        def url
          @url ||= example.url
        end

        def content
          @content ||= FileCache.read('app/_includes/plugins/example.md')
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
              'description' => example_config['description'],
              'credential_example' => credential_example
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

        def credential_example
          return nil unless credential_definition && example.consumer_credential?

          @credential_example ||= Drops::PluginCredentialExample.new(
            plugin_name: @plugin.name,
            example_formats: example.formats,
            definition: credential_definition
          )
        end

        def credential_definition
          @credential_definition ||= site.data.dig('plugins', 'credentials', @plugin.slug)
        end
      end
    end
  end
end
