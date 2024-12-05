# frozen_string_literal: true

require_relative '../../lib/site_accessor'

module Jekyll
  module PluginPages
    class Plugin
      extend Forwardable
      include Jekyll::SiteAccessor

      def_delegators :@release_info, :releases, :latest_available_release

      attr_reader :folder, :slug

      def initialize(folder:, slug:)
        @folder = folder
        @slug   = slug

        @release_info = release_info
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
        @formats ||= site.data.dig('entity_examples', 'config', 'formats').except('ui').keys
      end

      def example_files
        @example_files ||= Dir.glob(File.join(folder, 'examples', '*'))
      end

      def schema
        @schema ||= schemas.detect { |s| s.release == latest_available_release }
      end

      private

      def schemas
        @schemas ||= Schema.all(plugin: self)
      end

      def release_info
        ReleaseInfo::Product.new(
          site:,
          product:,
          min_version:,
          max_version:
        )
      end

      def product
        @product ||= metadata.fetch('products', []).first
      end

      def min_version
        @min_version ||= metadata.fetch('min_version', {})
      end

      def max_version
        @max_version ||= metadata.fetch('maxs_version', {})
      end
    end
  end
end
