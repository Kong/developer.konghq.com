# frozen_string_literal: true

module Jekyll
  class EnvironmentVariablesGenerator < Generator
    priority :highest

    def generate(site)
      site.config['git_branch'] = ENV['HEAD'] || 'main'
      site.config['ENABLE_KAPA_AI'] = ENV['ENABLE_KAPA_AI']
    end
  end
end
