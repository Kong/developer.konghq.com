# frozen_string_literal: true

module Jekyll
  class SkillsGenerator < Jekyll::Generator
    priority :high

    def generate(site)
      site.data['skills'] ||= {}
      Jekyll::SkillPages::Generator.run(site)
    end
  end
end
