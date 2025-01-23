# frozen_string_literal: true

require 'yaml'

module Jekyll
  module PluginPages
    module Pages
      class Example < Base
        def url
          @url ||= example.url
        end

        def content
          @content ||= File.read('app/_includes/plugins/example.md')
        end

        def data
          super
            .except('faqs')
            .merge(
              'example?' => true,
              'example' => example,
              'examples' => @plugin.examples,
              'content_type' => 'plugin_example',
              'no_version' => true
            )
        end

        def layout
          'plugins/example'
        end

        def example
          @example ||= @plugin.examples.detect { |e| e.file == @file }
        end
      end
    end
  end
end
