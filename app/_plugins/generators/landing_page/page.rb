# frozen_string_literal: true

module Jekyll
  module LandingPages
    class Page < Jekyll::Page
      def initialize(site, file)
        @site = site
        @data = YAML.load_file(file)

        # Set self.ext and self.basename by extracting information from the page filename
        process('index.md')

        @dir = output_path(file)

        @content = "HELLO WORLD"
        @data = {
          'title' => 'This is a test'
        }

        # Needed so that regeneration works for single sourced pages
        # It must be set to the source file
        # Also, @path MUST NOT be set, it falls back to @relative_path
        @relative_path = file

        @data['layout'] = 'default'
      end

      private

      def output_path(file)
        file.sub(@site.source, @site.dest).sub(/\/_landing_pages\/([\w\/]+)\.yaml$/, '/\1/')
      end
    end
  end
end
