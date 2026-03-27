# frozen_string_literal: true

require_relative '../../../lib/site_accessor'

module Jekyll
  module PromptPages
    module Pages
      class Page # rubocop:disable Style/Documentation
        include Jekyll::SiteAccessor

        def initialize(prompt:)
          @prompt = prompt
        end

        def to_jekyll_page
          CustomJekyllPage.new(site: site, page: self)
        end

        def url
          @prompt.url
        end

        def dir
          url
        end

        def content
          ''
        end

        def relative_path
          "_prompts/#{@prompt.slug}.yml"
        end

        def data
          @prompt.metadata.merge(
            'layout'      => 'prompt',
            'slug'        => @prompt.slug,
            'breadcrumbs' => ['/prompts/'],
            'kai_url'     => @prompt.kai_url
          )
        end
      end
    end
  end
end
