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
              'example' => example
            )
        end

        def layout
          'plugins/example'
        end

        def example
          @example ||= examples.detect { |e| e.file == @file }
        end
      end
    end
  end
end
