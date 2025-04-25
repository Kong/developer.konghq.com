# frozen_string_literal: true

require_relative './base'

module Jekyll
  module APIPages
    class ErrorPage < Base
      def initialize(product:, version:, file:, site:, errors:)
        @product = product
        @version = version
        @file = file
        @site = site
        @errors = errors
      end

      def data # rubocop:disable Metrics/MethodLength
        @data ||= {
          'title' => 'Errors',
          'api_spec' => api_spec,
          'description' => "#{api_spec.title} Custom Error Codes.",
          'layout' => 'api/errors',
          'content_type' => 'reference',
          'canonical_url' => canonical_url,
          'canonical?' => canonical?,
          'version' => @version,
          'seo_noindex' => seo_noindex,
          'errors' => @errors.map { |k, v| Drops::OAS::Error.new(code: k, values: v) },
          'breadcrumbs' => breadcrumbs
        }
      end

      def url_generator
        @url_generator ||= URLGenerator::Error.new(file:, version:, latest_version:)
      end

      def breadcrumbs
        ['/api/', url_generator.api_versioned_url]
      end
    end
  end
end
