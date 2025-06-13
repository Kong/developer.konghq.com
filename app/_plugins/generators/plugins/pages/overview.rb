# frozen_string_literal: true

module Jekyll
  module PluginPages
    module Pages
      class Overview < Base # rubocop:disable Style/Documentation
        def self.url(plugin)
          if plugin.unreleased?
            "/plugins/#{plugin.slug}/#{plugin.min_release}/"
          else
            "/plugins/#{plugin.slug}/"
          end
        end

        def content
          @content ||= parser.content
        end

        def layout
          'plugins/with_aside'
        end

        def data
          super.merge(
            'overview?' => true,
            'search_aliases' => @plugin.metadata['search_aliases'],
            'release' => @plugin.latest_release_in_range
          )
        end

        private

        def parser
          @parser ||= Jekyll::Utils::MarkdownParser.new(File.read(file))
        end
      end
    end
  end
end
