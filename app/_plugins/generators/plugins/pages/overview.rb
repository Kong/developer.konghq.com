# frozen_string_literal: true

module Jekyll
  module PluginPages
    module Pages
      class Overview < Base
        def url
          @url ||= "/plugins/#{@plugin.slug}/"
        end

        def content
          @content ||= parser.content
        end

        def layout
          'plugins/base'
        end

        private

        def parser
          @parser ||= Jekyll::Utils::MarkdownParser.new(
            File.read(file)
          )
        end

        def file
          @file ||= File.join(@plugin.folder, 'index.md')
        end
      end
    end
  end
end
