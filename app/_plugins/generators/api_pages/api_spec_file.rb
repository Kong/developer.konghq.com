# frozen_string_literal: true

require 'yaml'

module Jekyll
  module APIPages
    class APISpecFile
      def initialize(site:, page_source_file:, version:)
        @site = site
        @page_source_file = page_source_file
        @version = version
      end

      def path
        @path ||= File.expand_path(relative_path.prepend('../'), @site.source)
      end

      def exist?
        File.exist?(path)
      end

      def relative_path
        @relative_path ||= @page_source_file
                           .dup
                           .gsub('_api', 'api-specs')
                           .gsub('_index.md', "#{@version}/")
                           .concat('openapi.yaml')
      end

      def raw_api_spec
        return unless exist?

        @raw_api_spec ||= YAML.load(File.read(path))
      end
    end
  end
end
