# frozen_string_literal: true

require_relative '../lib/ordered_generator'

module Jekyll
  class EnvironmentVariablesGenerator < OrderedGenerator
    def generate(site)
      site.config['git_branch'] = ENV['HEAD'] || 'main'
      site.config['ENABLE_KAPA_AI'] = ENV['ENABLE_KAPA_AI']
      site.config['ENABLE_ADOBE'] = ENV['ENABLE_ADOBE'] == '1'
      site.config['ENABLE_ALGOLIA'] = enable_algolia
      site.config['konnect_domain'] = ENV['KONNECT_DOMAIN'].to_s.empty? ? 'konghq.com' : ENV['KONNECT_DOMAIN']
    end

    private

    def enable_algolia
      return ENV['ENABLE_ALGOLIA'] == '1' if ENV['ENABLE_ALGOLIA']

      ENV['JEKYLL_ENV'] == 'development'
    end
  end
end
