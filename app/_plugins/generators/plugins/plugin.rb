# frozen_string_literal: true

require_relative '../../lib/site_accessor'

module Jekyll
  module PluginPages
    class Plugin
      extend Forwardable
      include Jekyll::SiteAccessor

      def_delegators :@release_info, :releases, :latest_available_release,
                     :latest_release_in_range, :unreleased?

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
        @targets ||= begin
          targets = %w[consumer consumer_group service route].select do |t|
            schema.as_json.dig('properties', t)
          end
          targets << 'global'
          targets.sort
        end
      end

      def formats
        @formats ||= site.data.dig('entity_examples', 'config', 'formats')
                         .except('ui')
                         .tap { |h| h.delete('konnect-api') unless works_on.include?('konnect') }
                         .keys
      end

      def example_files
        @example_files ||= Dir.glob(File.join(folder, 'examples', '*'))
      end

      def examples
        @examples ||= example_files.map do |file|
          Drops::PluginConfigExample.new(
            file: file,
            plugin: self
          )
        end.sort_by { |e| -e.weight } # rubocop:disable Style/MultilineBlockChain
      end

      def schema
        @schema ||= schemas.detect { |s| s.release == latest_release_in_range }
      end

      def schemas
        @schemas ||= Drops::Plugins::Schema.all(plugin: self)
      end

      def icon
        @icon ||= metadata.fetch('icon')
      end

      def name
        @name ||= metadata.fetch('name')
      end

      def works_on
        @works_on ||= metadata['works_on']
      end

      def changelog_exists?
        return @changelog_exists if defined?(@changelog_exists)

        @changelog_exists = File.exist?(File.join(folder, 'changelog.md'))
      end

      def third_party?
        metadata['third_party']
      end

      private

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
