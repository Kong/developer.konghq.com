# frozen_string_literal: true

module Jekyll
  class EnvironmentVariablesGenerator < Generator
    priority :highest

    def generate(site)
      site.config['git_branch'] = ENV['HEAD'] || 'main'
      site.config['ENABLE_KAPA_AI'] = ENV['ENABLE_KAPA_AI']
      site.config['ENABLE_ALGOLIA'] = enable_algolia
    end

    private

    def enable_algolia
      return ENV['ENABLE_ALGOLIA'] == '1' if ENV['ENABLE_ALGOLIA']

      ENV['JEKYLL_ENV'] == 'development'
    end
  end
end
