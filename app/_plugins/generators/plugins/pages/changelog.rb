# frozen_string_literal: true

require 'yaml'

module Jekyll
  module PluginPages
    module Pages
      class Changelog < Base
        def self.url(plugin)
          if plugin.unreleased?
            "/plugins/#{plugin.slug}/changelog/#{plugin.min_release}/"
          else
            "/plugins/#{plugin.slug}/changelog/"
          end
        end

        def content
          @content ||= parser.content
        end

        def data
          super
            .except('faqs')
            .merge(metadata, 'changelog?' => true)
        end

        def metadata
          @metadata ||= parser.frontmatter
        end

        def layout
          'plugins/with_aside'
        end

        private

        def parser
          @parser ||= Jekyll::Utils::MarkdownParser.new(File.read(file))
        end
      end
    end
  end
end
