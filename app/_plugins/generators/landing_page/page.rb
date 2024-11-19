# frozen_string_literal: true

module Jekyll
  module LandingPages
    class Page < Jekyll::Page
      def initialize(site, file)
        @site = site
        data = load_file(file)

        # Set self.ext and self.basename by extracting information from the page filename
        process('index.md')

        @dir = output_path(file)

        @content = ''
        @data = data.fetch('metadata', {})
        @data['rows'] = data['rows']

        # Needed so that regeneration works for single sourced pages
        # It must be set to the source file
        # Also, @path MUST NOT be set, it falls back to @relative_path
        @relative_path = file.gsub("#{@site.source}/", '')

        @data['layout'] = 'landing_page'
      end

      def url
        @dir.sub(@site.dest, '')
      end

      private

      def load_file(file)
        data = YAML.load_file(file)

        raise ArgumentError, "Landing pages: The file #{file} is empty." if data.nil?

        data
      end

      def output_path(file)
        file.sub(@site.source, @site.dest).sub(%r{/_landing_pages/(.+)\.yaml$}, '/\1/')
      end
    end
  end
end
