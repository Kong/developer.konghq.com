# frozen_string_literal: true

module Jekyll
  module PluginPages
    module Pages
      class Base
        attr_reader :file

        def initialize(site:, plugin:, file:)
          @site   = site
          @plugin = plugin
          @file   = file
        end

        def to_jekyll_page
          CustomJekyllPage.new(site: @site, page: self)
        end

        def dir
          url
        end

        def data
          @plugin.metadata.merge(
            'slug'   => @plugin.slug,
            'plugin?' => true,
            'layout' => layout,
            'examples' => examples
          )
        end

        def relative_path
          @relative_path = file.gsub("#{@site.source}/", "")
        end

        private

        def examples
          @examples ||= @plugin.example_files.map do |file|
            Drops::PluginConfigExample.new(
              file: file,
              plugin: @plugin,
            )
          end
        end
      end
    end
  end
end
