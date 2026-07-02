# frozen_string_literal: true

require_relative '../../lib/site_accessor'

module Jekyll
  module AIGatewayPluginPages
    class Plugin
      include Jekyll::SiteAccessor

      attr_reader :folder, :slug

      def initialize(folder:, slug:)
        @folder = folder
        @slug   = slug
      end

      def metadata
        @metadata ||= Jekyll::Utils::MarkdownParser.new(
          File.read(File.join(@folder, 'index.md'))
        ).frontmatter
      end

      def schema
        @schema ||= Jekyll::Drops::Plugins::AIGWPolicySchema.new(slug: @slug)
      end

      def name
        @name ||= metadata.fetch('name')
      end

      def icon
        @icon ||= metadata['icon']
      end
    end
  end
end
