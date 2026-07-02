# frozen_string_literal: true

module Jekyll
  module AIGatewayPluginPages
    class Generator
      PLUGINS_FOLDER = '_ai_gateway_plugins'

      def self.run(site)
        new(site).run
      end

      attr_reader :site

      def initialize(site)
        @site = site
      end

      def run
        return if skip?

        Dir.glob(File.join(site.source, "#{PLUGINS_FOLDER}/*/")).each do |folder|
          slug = folder.gsub("#{site.source}/#{PLUGINS_FOLDER}/", '').chomp('/')
          generate_pages(Plugin.new(folder:, slug:))
        end
      end

      private

      def generate_pages(plugin)
        generate_overview_page(plugin)
        generate_reference_page(plugin)
      end

      def generate_overview_page(plugin)
        overview = Pages::Overview
                   .new(plugin:, file: File.join(plugin.folder, 'index.md'))
                   .to_jekyll_page
        site.data['ai_gateway_plugins'][plugin.slug] = overview
        site.pages << overview
      end

      def generate_reference_page(plugin)
        reference = Pages::Reference
                    .new(plugin:, file: File.join(plugin.folder, 'reference.md'))
                    .to_jekyll_page
        site.pages << reference
      end

      def skip?
        site.config.dig('skip', 'ai_gateway_plugins')
      end
    end
  end
end
