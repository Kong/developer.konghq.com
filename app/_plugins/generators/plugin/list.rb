# frozen_string_literal: true

module Jekyll
  module KongPlugin
    class List < Jekyll::Page
      def initialize(site, all_plugins)
        @site = site

        # Set self.ext and self.basename by extracting information from the page filename
        process('index.md')

        @dir = "#{@site.dest}/plugins/"
        @data = {
          'layout' => 'plugin_list',
          'plugins' => all_plugins
        }
      end
    end
  end
end
