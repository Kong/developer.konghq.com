# frozen_string_literal: true

require_relative '../../../lib/site_accessor'

module Jekyll
  module AIGatewayPluginPages
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

        def url
          @url ||= self.class.url(@plugin)
        end

        def relative_path
          @relative_path = file.gsub("#{site.source}/", '')
        end

        def layout
          raise NotImplementedError, "#{self.class} must implement #layout"
        end

        def data
          @plugin.metadata.merge(page_info).merge(page_urls)
        end

        private

        def page_info
          {
            'slug' => @plugin.slug,
            'layout' => layout,
            'breadcrumbs' => ['/ai-gateway/', '/ai-gateway/on-prem/plugins/'],
            'plugin' => @plugin,
            'plugin?' => true,
            'schema' => @plugin.schema,
            'has_overview?' => true,
            'icon' => icon
          }
        end

        def page_urls
          {
            'overview_url' => Pages::Overview.url(@plugin),
            'reference_url' => Pages::Reference.url(@plugin)
          }
        end

        def icon
          return unless @plugin.icon

          "/assets/icons/plugins/#{@plugin.icon}"
        end
      end
    end
  end
end
