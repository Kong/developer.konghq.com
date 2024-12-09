# frozen_string_literal: true

require 'yaml'

module Jekyll
  module PluginPages
    module Pages
      class Example < Base
        def url
          @url ||= "/plugins/#{@plugin.slug}/examples/#{example.slug}/"
        end

        def content
          ''
        end

        def data
          super
            .except('faqs')
            .merge(
              'example?' => true,
              'example' => example,
              'examples' => examples
            )
        end

        def layout
          'plugins/example'
        end

        def example
          @example ||= examples.detect { |e| e.file == @file }
        end

        def examples
          @examples ||= @plugin.example_files.map do |file|
            Drops::PluginConfigExample.new(
              file: file,
              plugin: @plugin
            )
          end
        end
      end
    end
  end
end
