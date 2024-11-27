# frozen_string_literal: true

require_relative './error_page'

module Jekyll
  module APIPages
    class CanonicalError < APIPages::ErrorPage
      def dir
        @dir ||= canonical_url
      end

      def data
        super.tap { |d| d.delete('seo_noindex') }
      end
    end
  end
end
