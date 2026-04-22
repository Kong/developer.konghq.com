# frozen_string_literal: true

module Jekyll
  class PromptsGenerator < Jekyll::Generator
    priority :high

    def generate(site)
      site.data['prompts'] ||= []
      Jekyll::PromptPages::Generator.run(site)
    end
  end
end
