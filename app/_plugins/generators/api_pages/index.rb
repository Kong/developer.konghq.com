# frozen_string_literal: true

module Jekyll
  module APIPages
    class Index
      def initialize(site:)
        @site = site
      end

      def to_jekyll_page
        CustomJekyllPage.new(site: @site, page: self)
      end

      def dir
        @dir ||= '/api/'
      end

      def relative_path
        @relative_path ||= 'api'
      end

      def content
        @content ||= ''
      end

      def url
        @url || dir
      end

      def data
        {
          'title' => 'OpenAPI Specifications',
          'description' => 'Directory of OpenAPI specifications for various Kong APIs.',
          'layout' => 'api/index',
          'content_type' => 'reference',
          'get_help' => false,
          'edit_and_issue_links' => false
        }
      end
    end
  end
end
