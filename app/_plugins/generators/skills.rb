# frozen_string_literal: true

module Jekyll
  class SkillsGenerator < Jekyll::Generator
    priority :high

    def generate(site)
      site.data['skills'] = {}
      site.data['skills_plugins'] = []
      site.data['skills_power'] = nil
      site.data['skills_filters'] = {
        'plugins' => [],
        'products' => [],
        'categories' => []
      }
      site.data['skill_install_tabs'] = []

      Jekyll::SkillPages::Generator.run(site)
    end
  end
end
