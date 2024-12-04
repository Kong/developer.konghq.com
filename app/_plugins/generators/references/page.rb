# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/object/deep_dup'

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
                   "#{@page.url}#{@release}/"
                 else
                   "#{@page.dir}#{@release}/"
                 end
      end

      def data
        @data ||= @page.data
                       .deep_dup
                       .except('published')
                       .merge(
                         'release' => @release,
                         'seo_noindex' => true,
                         'canonical?' => url == @page.data['canonical_url']
                       )
      end

      def relative_path
        @relative_path ||= @page.relative_path
      end

      def content
        @content ||= @page.content.deep_dup
      end

      def url
        @url ||= dir
      end
    end
  end
end
