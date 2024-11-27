# frozen_string_literal: true

require_relative './page'

module Jekyll
  module APIPages
    class CanonicalPage < APIPages::Page
      def dir
        @dir ||= canonical_url
      end

      def data
        super.tap { |d| d.delete('seo_noindex') }
      end
    end
  end
end
