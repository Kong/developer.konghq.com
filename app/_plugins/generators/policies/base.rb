# frozen_string_literal: true

require_relative '../../lib/site_accessor'

module Jekyll
  module Policies
    module Base # rubocop:disable Style/Documentation
      extend Forwardable
      include Jekyll::SiteAccessor

      def_delegators :@release_info, :releases, :latest_available_release,
                     :latest_release_in_range, :unreleased?, :major_version_number

      attr_reader :folder, :slug, :explicit_major

      def initialize(folder:, slug:, policy_major: nil)
        @folder = folder
        @slug   = slug
        @explicit_major = policy_major

        @release_info = release_info
      end

      def policy_major
        @policy_major ||= explicit_major || major_version_number
      end

      def metadata
        @metadata ||= Jekyll::Utils::MarkdownParser.new(index_file).frontmatter
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
          max_version:,
          major: explicit_major
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

      private

      def index_file
        @index_file ||= File.read(File.join(@folder, 'index.md'))
      end
    end
  end
end
