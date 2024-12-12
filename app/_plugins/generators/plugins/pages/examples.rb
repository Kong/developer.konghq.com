# frozen_string_literal: true

module Jekyll
  module PluginPages
    module Pages
      class Examples < Base
        def self.url(slug)
          "/plugins/#{slug}/examples/"
        end

        def content
          ''
        end

        def data
          super
            .except('faqs')
            .merge(
              'examples?' => true,
              'examples' => examples,
              'content_type' => 'reference',
              'no_version' => true
            )
        end

        def layout
          'plugins/examples'
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
