# frozen_string_literal: true

module Jekyll
  module PluginPages
    class Plugin
      attr_reader :folder, :slug, :site

      def initialize(site:, folder:, slug:)
        @site   = site
        @folder = folder
        @slug   = slug
      end

      def metadata
        @metadata ||= Jekyll::Utils::MarkdownParser.new(
          File.read(File.join(@folder, 'index.md'))
        ).frontmatter
      end

      def targets
        # TODO: pull targets from the schema when we have them
        @targets = %w[consumer consumer_group service global route]
      end

      def formats
        @formats ||= @site.data.dig('entity_examples', 'config', 'formats').except('ui').keys
      end

      def example_files
        @example_files ||= Dir.glob(File.join(folder, 'examples', '*'))
      end
    end
  end
end
