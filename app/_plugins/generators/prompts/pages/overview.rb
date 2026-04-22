# frozen_string_literal: true

module Jekyll
  module PromptPages
    module Pages
      class Overview < Base
        def self.url(prompt)
          "/prompts/#{prompt.slug}/"
        end

        def content
          @content ||= File.read('app/_includes/prompts/overview.md')
        end

        def layout
          'prompts/overview'
        end

        def data
          super.merge('overview?' => true, 'content_type' => 'prompt')
        end
      end
    end
  end
end
