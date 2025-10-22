# frozen_string_literal: true

require_relative './base'

module Jekyll
  module APIPages
    class Page < Base
      attr_reader :product, :version, :site

      def initialize(product:, version:, file:, site:, frontmatter:)
        @product = product
        @version = version
        @file = file
        @site = site
        @frontmatter = frontmatter
      end

      def data # rubocop:disable Metrics/MethodLength
        @data ||= {
          'title' => api_spec.title,
          'base_url' => base_url,
          'api_spec' => api_spec,
          'description' => api_spec.description,
          'layout' => 'api/spec',
          'content_type' => 'api',
          'canonical_url' => canonical_url,
          'canonical?' => canonical?,
          'seo_noindex' => seo_noindex,
          'namespace' => namespace,
          'breadcrumbs' => ['/api/'],
          'version' => @version,
          'versions_dropdown' => Drops::OAS::VersionsDropdown.new(base_url:, product:),
          'insomnia_link' => insomnia_link,
          'edit_and_issue_links' => false,
          'sidebar' => false
        }.merge(@frontmatter)
      end

      private

      def insomnia_link
        @insomnia_link ||= Drops::OAS::InsomniaLink.new(
          label: api_spec.title,
          version:,
          site:,
          page_relative_path: relative_path.dup
        )
      end

      def namespace
        @namespace ||= @file.split('/')[1]
      end

      def url_generator
        @url_generator ||= URLGenerator::API.new(file:, version:, latest_version:)
      end
    end
  end
end
