# frozen_string_literal: true

require_relative 'prompt/generator'

module Jekyll
  class PromptsGenerator < Jekyll::Generator # rubocop:disable Style/Documentation
    priority :high

    def generate(site)
      site.data['prompts'] ||= []
      Jekyll::PromptPages::Generator.run(site)
    end
  end
end
