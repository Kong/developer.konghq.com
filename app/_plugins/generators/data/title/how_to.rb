# frozen_string_literal: true

require_relative 'base'

module Jekyll
  module Data
    module Title
      class HowTo < Base # rubocop:disable Style/Documentation
        def title_sections
          [
            "How to: #{page_title}"
          ]
        end

        def llm_title
          "How to: #{page_title}"
        end
      end
    end
  end
end
