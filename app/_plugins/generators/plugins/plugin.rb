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
        overview = Jekyll::PluginPages::Pages::Overview
          .new(site:, plugin: self)
          .to_jekyll_page

        site.data['kong_plugins'][@slug] = overview
        site.pages << overview

        reference = Jekyll::PluginPages::Pages::Reference
          .new(site:, plugin: self)
          .to_jekyll_page

        site.pages << reference
      end

      def metadata
        @metadata ||= Jekyll::Utils::MarkdownParser.new(
          File.read(File.join(@folder, 'index.md'))
        ).frontmatter
      end
    end
  end
end
