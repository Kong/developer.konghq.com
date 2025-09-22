# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/object/deep_dup'

module Jekyll
  module ReferencePages
    module Page
      class Base
        def self.make_for(site:, page:, release:)
          if page.data['plugin?'] && (page.data['reference_type'].nil? || page.data['reference_type'] != 'base')
            Plugin.new(site:, page:, release:)
          else
            new(site:, page:, release:)
          end
        end

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
end
