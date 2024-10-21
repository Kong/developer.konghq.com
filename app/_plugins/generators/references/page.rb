# frozen_string_literal: true

module Jekyll
  module ReferencePages
    class Page
      def initialize(site:, page:, release:)
        @site    = site
        @page    = page
        @release = release
      end

      def to_jekyll_page
        CustomJekyllPage.new(site: @site, page: self)
      end

      def dir
        @dir ||= if @page.is_a?(Jekyll::Document)
          "#{@page.url}#{@release['release']}/"
        else
          "#{@page.dir}#{@release['release']}/"
          end
      end

      def data
        @data ||= @page.data.dup
          .merge('release' => @release, 'canonical_url' => @page.url)
      end

      def relative_path
        @relative_path ||= @page.relative_path
      end

      def content
        @content ||= @page.content
      end

      def url
        @url ||= dir
      end
    end
  end
end