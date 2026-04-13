# frozen_string_literal: true

require_relative '../../../lib/site_accessor'

module Jekyll
  module PromptPages
    module Pages
      class Base
        include Jekyll::SiteAccessor

        attr_reader :prompt

        def initialize(prompt:)
          @prompt = prompt
        end

        def to_jekyll_page
          CustomJekyllPage.new(site:, page: self)
        end

        def dir
          url
        end

        def relative_path
          @relative_path ||= prompt.file.gsub("#{site.source}/", '')
        end

        def data
          {
            'title' => prompt.title,
            'description' => prompt.description,
            'extended_description' => prompt.extended_description,
            'products' => prompt.products,
            'prompts' => prompt.prompts,
            'slug' => prompt.slug,
            'content_type' => 'prompt',
            'layout' => layout,
            'breadcrumbs' => ['/prompts/']
          }
        end

        def url
          @url ||= self.class.url(prompt)
        end
      end
    end
  end
end
