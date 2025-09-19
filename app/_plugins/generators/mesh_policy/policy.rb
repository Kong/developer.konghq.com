# frozen_string_literal: true

require_relative '../../lib/site_accessor'

module Jekyll
  module MeshPolicyPages
    class Policy # rubocop:disable Style/Documentation
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

      def example_files
        @example_files ||= Dir.glob(File.join(folder, 'examples', '*'))
      end

      def examples
        @examples ||= example_files.map do |file|
          Drops::MeshPolicyExample.new(
            file: file,
            policy: self
          )
        end.sort_by { |e| -e.weight } # rubocop:disable Style/MultilineBlockChain
      end

      def min_release
        @min_release ||= release_info.min_release
      end

      def publish?
        !(unreleased? && ENV['JEKYLL_ENV'] == 'production')
      end

      def schemas
        @schemas ||= Drops::MeshPolicies::Schema.all(policy: self)
      end

      def schema
        @schema ||= schemas.detect { |s| s.release == latest_release_in_range }
      end

      def type
        @type ||= metadata.fetch('type', 'policy')
      end

      def name
        @name ||= metadata.fetch('name')
      end

      def icon
        @icon ||= metadata['icon']
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
        @max_version ||= metadata.fetch('max_version', {})
      end
    end
  end
end
