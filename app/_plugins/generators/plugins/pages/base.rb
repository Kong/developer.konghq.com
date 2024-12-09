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
            'tools' => @plugin.formats,
            'breadcrumbs' => ['/plugins/'],
            'compatible_protocols' => compatible_protocols,
            'schema' => schema.to_json,
            'plugin' => @plugin,
            'overview_url' => Overview.url(@plugin.slug),
            'changelog_url' => Changelog.url(@plugin.slug),
            'reference_url' => reference_url
          )
        end

        def relative_path
          @relative_path = file.gsub("#{site.source}/", '')
        end

        def compatible_protocols
          @compatible_protocols ||= schema.compatible_protocols
        end

        def url
          @url ||= self.class.url(@plugin.slug)
        end

        private

        def reference_url
          base_url = Reference.url(@plugin.slug)
          return base_url unless @plugin.unreleased?

          "#{base_url}#{@plugin.latest_release_in_range}/"
        end

        def schema
          @schema ||= @plugin.schema
        end
      end
    end
  end
end
