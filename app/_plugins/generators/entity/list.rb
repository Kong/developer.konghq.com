# frozen_string_literal: true

module Jekyll
  module KongEntity
    class List < Jekyll::Page
      def initialize(site, all_entities)
        @site = site

        # Set self.ext and self.basename by extracting information from the page filename
        process('index.md')

        @dir = "#{@site.dest}/kong-entities/"
        @data = {
          'layout' => 'plugin_list',
          'plugins' => all_entities
        }
      end
    end
  end
end
