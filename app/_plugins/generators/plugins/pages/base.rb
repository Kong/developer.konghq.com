# frozen_string_literal: true

require_relative '../../../lib/site_accessor'

module Jekyll
  module PluginPages
    module Pages
      class Base
        include Jekyll::SiteAccessor

        attr_reader :file

        def initialize(plugin:, file:)
          @plugin = plugin
          @file   = file
        end

        def to_jekyll_page
          CustomJekyllPage.new(site:, page: self)
        end

        def dir
          url
        end

        def data
          @plugin.metadata.merge(
            'slug' => @plugin.slug,
            'plugin?' => true,
            'layout' => layout,
            'examples' => examples,
            'tools' => @plugin.formats,
            'breadcrumbs' => ['/plugins/'],
            'compatible_protocols' => compatible_protocols,
            'schema' => schema.to_json,
            'plugin' => @plugin
          )
        end

        def relative_path
          @relative_path = file.gsub("#{site.source}/", '')
        end

        def compatible_protocols
          @compatible_protocols ||= schema.compatible_protocols
        end

        private

        def schema
          @schema ||= @plugin.schema
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
