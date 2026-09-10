# frozen_string_literal: true

require_relative '../../file_cache'

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
        @content ||= FileCache.read('app/_includes/api_specs.html')
      end

      def url
        @url || dir
      end

      def data
        {
          'title' => 'API Reference',
          'description' => 'Directory of OpenAPI specifications for various Kong APIs.',
          'layout' => 'api/index',
          'get_help' => false,
          'edit_and_issue_links' => false,
          'search_aliases' => ['oas', 'specs', 'api specs']
        }
      end
    end
  end
end
