# frozen_string_literal: true

module Jekyll
  module LearningPath
    class Page < Jekyll::Page # rubocop:disable Style/Documentation
      attr_reader :source_data

      def initialize(site, file) # rubocop:disable Lint/MissingSuper
        @site = site
        @source_data = load_file(file)

        # Set self.ext and self.basename by extracting information from the filename
        process('index.md')

        @dir = output_path(file)

        @content = ''
        @data = @source_data.fetch('metadata', {})
        @data['steps'] = @source_data['steps'] || []
        @data['content_type'] = 'learning_path'
        @data['layout'] = 'learning-path'
        @data['breadcrumbs'] ||= ['/learning-paths/']

        # Needed so that regeneration works for single sourced pages.
        # It must be set to the source file.
        # Also, @path MUST NOT be set; it falls back to @relative_path.
        @relative_path = file.gsub("#{@site.source}/", '')
      end

      def url
        @url ||= @dir.sub(@site.dest, '')
      end

      private

      def load_file(file)
        data = YAML.load_file(file)
        raise ArgumentError, "Learning paths: The file #{file} is empty." if data.nil?

        data
      end

      def output_path(file)
        file.sub(@site.source, @site.dest)
            .sub(%r{/_learning-paths/(.+)\.yaml$}, '/learning-paths/\1/')
      end
    end
  end
end
