# frozen_string_literal: true

require_relative '../../../lib/site_accessor'

module Jekyll
  module PluginPages
    module Pages
      class Base # rubocop:disable Style/Documentation
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

        def data # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
          @plugin.metadata
                 .except('search_aliases')
                 .merge(
                   'slug' => @plugin.slug,
                   'plugin?' => true,
                   'layout' => layout,
                   'tools' => @plugin.formats,
                   'breadcrumbs' => ['/plugins/'],
                   'compatible_protocols' => compatible_protocols,
                   'schema' => schema,
                   'plugin' => @plugin,
                   'overview_url' => Overview.url(@plugin),
                   'changelog_exists?' => @plugin.changelog_exists?,
                   'changelog_url' => Changelog.url(@plugin),
                   'get_started_url' => @plugin.examples.first.url,
                   'reference_url' => Reference.url(@plugin),
                   'icon' => icon,
                   'api_spec_exists?' => @plugin.api_spec_exists?,
                   'api_reference_url' => ApiReference.url(@plugin),
                   'sidebar' => false
                 ).merge(publication_info)
        end

        def relative_path
          @relative_path = file.gsub("#{site.source}/", '')
        end

        def compatible_protocols
          @compatible_protocols ||= schema.compatible_protocols
        end

        def url
          @url ||= self.class.url(@plugin)
        end

        private

        def icon
          @icon ||= "/assets/icons/plugins/#{@plugin.icon}"
        end

        def schema
          @schema ||= @plugin.schema
        end

        def publication_info
          return {} if @plugin.publish?

          { 'published' => false }
        end
      end
    end
  end
end
