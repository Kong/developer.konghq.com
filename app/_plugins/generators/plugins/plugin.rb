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

      def generate_pages
        generate_overview_page
        generate_reference_page
        generate_changelog_page
        generate_example_pages
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

      private

      def generate_overview_page
        overview = Jekyll::PluginPages::Pages::Overview
                   .new(site:, plugin: self, file: File.join(@folder, 'index.md'))
                   .to_jekyll_page

        site.data['kong_plugins'][@slug] = overview
        site.pages << overview
      end

      def generate_reference_page
        reference = Jekyll::PluginPages::Pages::Reference
                    .new(site:, plugin: self, file: File.join(@folder, 'reference.yaml'))
                    .to_jekyll_page

        site.pages << reference
      end

      def generate_changelog_page
        changelog = Jekyll::PluginPages::Pages::Changelog
                    .new(site:, plugin: self, file: File.join(@folder, 'changelog.md'))
                    .to_jekyll_page

        site.pages << changelog
      end

      def generate_example_pages
        example_files.each do |example_file|
          example = Jekyll::PluginPages::Pages::Example
                    .new(site:, plugin: self, file: example_file)
                    .to_jekyll_page

          site.pages << example
        end
      end
    end
  end
end
