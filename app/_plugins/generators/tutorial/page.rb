# frozen_string_literal: true

module Jekyll
  module Tutorial
    class Page < Jekyll::Page
      def initialize(site, file)
        @site = site
        content = File.read(file)

        # Set self.ext and self.basename by extracting information from the page filename
        process('index.md')

        @dir = output_path(file)

        # Load content + frontmatter from the file
        if content =~ Jekyll::Document::YAML_FRONT_MATTER_REGEXP
          @content = Regexp.last_match.post_match
          @data = SafeYAML.load(Regexp.last_match(1))
        end

        # Needed so that regeneration works for single sourced pages
        # It must be set to the source file
        # Also, @path MUST NOT be set, it falls back to @relative_path
        @relative_path = file

        @data['layout'] = 'tutorial'
      end

      def url
        @dir.sub(@site.dest, '')
      end

      private

      def output_path(file)
        file.sub(@site.source, @site.dest).sub(%r{/_tutorials/([\w/-]+)\.md$}, '/tutorials/\1/')
      end
    end
  end
end
