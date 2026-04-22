# frozen_string_literal: true

require_relative 'base'

module Jekyll
  module Data
    module Title
      class Prompt < Base
        def title_sections
          [page_title, 'Prompts']
        end

        def llm_title
          page_title
        end
      end
    end
  end
end
