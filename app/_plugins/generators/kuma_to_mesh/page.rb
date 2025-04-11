# frozen_string_literal: true

module Jekyll
  module KumatoMesh
    class Page # rubocop:disable Style/Documentation
      attr_reader :site, :page_config

      def initialize(site:, page_config:)
        @site = site
        @page_config = page_config
      end

      def dir
        @dir ||= url
      end

      def content
        @content ||= markdown_parser.content
      end

      def data
        frontmatter
          .merge(@page_config.except('path', 'url'))
          .merge(mesh_metadata)
          .merge(release_metadata)
      end

      def url
        @url ||= @page_config.fetch('url')
      end

      def relative_path
        @relative_path ||= file_path
      end

      def to_jekyll_page
        CustomJekyllPage.new(site: @site, page: self)
      end

      private

      def mesh_metadata
        @mesh_metadata ||= @site.data.dig('kuma_to_mesh', 'config', 'metadata') || {}
      end

      def release_metadata
        release = release_info.latest_release_in_range
        {
          'release' => release,
          'version_data' => release.release_hash
        }
      end

      def file_path
        @file_path ||= File.join('app/.repos/kuma/', @page_config.fetch('path'))
      end

      def markdown_parser
        @markdown_parser ||= Jekyll::Utils::MarkdownParser.new(File.read(file_path))
      end

      def frontmatter
        @frontmatter ||= markdown_parser.frontmatter
      end

      def release_info
        @release_info ||= ReleaseInfo::Product.new(
          site:,
          product: mesh_metadata['products'].first,
          min_version: page_config.fetch('min_version', {}),
          max_version: {}
        )
      end
    end
  end
end
