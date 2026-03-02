# frozen_string_literal: true

require_relative 'base'

module Jekyll
  module Data
    module Title
      class APIPage < Base # rubocop:disable Style/Documentation
        def title_sections
          return [page_title] if @page.url == '/api/'

          [
            title,
            'OpenAPI Specification',
            version
          ]
        end

        def llm_title
          return page_title if @page.url == '/api/'

          [
            title,
            'OpenAPI Specification'
          ].join(' ')
        end

        def version
          return if @page.data['canonical?']

          v = @page.data['version']
          Gem::Version.correct?(v) ? "v#{v}" : v
        end

        def title
          return page_title if @page.url == '/api/errors/'

          case @page.data['content_type']
          when 'api'
            page_title
          when 'reference'
            "#{@page.data['api_spec'].title} - #{page_title}"
          else
            page_title
          end
        end
      end
    end
  end
end
