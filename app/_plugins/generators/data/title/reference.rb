# frozen_string_literal: true

require_relative 'base'

module Jekyll
  module Data
    module Title
      class Reference < Base # rubocop:disable Style/Documentation
        def title_sections
          [
            page_title,
            version,
            product_or_tool
          ]
        end

        def llm_title
          page_title
        end

        def version
          return if @page.data['canonical?']

          v = @page.data['release']
          Gem::Version.correct?(v) ? "v#{v}" : v
        end

        def product_or_tool
          if product.nil?
            @site.data.dig('tools', tool, 'name')
          else
            @site.data.dig('products', product, 'name')
          end
        end

        def product
          @product ||= @page.data.fetch('products', []).first
        end

        def tool
          @tool ||= @page.data.fetch('tools', []).first
        end
      end
    end
  end
end
