# frozen_string_literal: true

module Jekyll
  module Tutorial
    class List < Jekyll::Page
      def initialize(site, all_tutorials)
        @site = site

        # Set self.ext and self.basename by extracting information from the page filename
        process('index.md')

        @dir = "#{@site.dest}/tutorials/"
        @data = {
          'layout' => 'tutorial_list',
          'tutorials' => all_tutorials
        }
      end
    end
  end
end
