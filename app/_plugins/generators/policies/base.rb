# frozen_string_literal: true

require_relative '../../lib/site_accessor'

module Jekyll
  module Policies
    module Base # rubocop:disable Style/Documentation
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

      def min_release
        @min_release ||= release_info.min_release
      end

      def publish?
        !(unreleased? && ENV['JEKYLL_ENV'] == 'production')
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
