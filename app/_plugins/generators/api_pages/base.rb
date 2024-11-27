# frozen_string_literal: true

module Jekyll
  module APIPages
    class Base
      attr_reader :product, :version, :file

      def to_jekyll_page
        CustomJekyllPage.new(site: @site, page: self)
      end

      def dir
        @dir ||= url_generator.versioned_url
      end

      def relative_path
        @relative_path ||= @file
      end

      def content
        @content ||= ''
      end

      def url
        @url ||= dir
      end

      private

      def api_spec
        @api_spec ||= Drops::OAS::APISpec.new(product:, version:)
      end

      def canonical_url
        @canonical_url ||= url_generator.canonical_url
      end
    end
  end
end
