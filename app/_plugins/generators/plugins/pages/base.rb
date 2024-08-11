# frozen_string_literal: true

module Jekyll
  module PluginPages
    module Pages
      class Base
        def initialize(site:, plugin:)
          @site   = site
          @plugin = plugin
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
            'layout' => layout
          )
        end

        def relative_path
          @relative_path = file.gsub("#{@site.source}/", "")
        end
      end
    end
  end
end
