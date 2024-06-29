# frozen_string_literal: true

module Jekyll
  class TutorialGenerator < Jekyll::Generator
    priority :low

    def generate(site)
      Jekyll::Tutorial::Generator.run(site)
    end
  end
end
