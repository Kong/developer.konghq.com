# frozen_string_literal: true

require_relative 'api_pages'
require_relative 'broken_links'
require_relative 'environment_variables'
require_relative 'event_gateway_policies'
require_relative 'explorer'
require_relative 'indices'
require_relative 'landing_page'
require_relative 'markdown_pages_generator'
require_relative 'mesh_policies'
require_relative 'page_data'
require_relative 'plugins'
require_relative 'plugins_ai_gateway_policies'
require_relative 'redirects'
require_relative 'reference_pages'
require_relative 'release_map_loader'
require_relative 'site_data'
require_relative 'sitemap'
require_relative 'skills'

module Jekyll
  # The single Jekyll::Generator for everything under app/_plugins/generators.
  #
  # Jekyll sorts generators with an unstable sort over priority bands only, so
  # same-band ties resolve per-machine. This class replaces that with one
  # explicit order.

  class GeneratorOrchestrator < Jekyll::Generator
    priority :high

    ORDER = [
      EnvironmentVariablesGenerator,
      SiteDataGenerator,
      EventGatewayPoliciesGenerator,
      LandingPagesGenerator,
      MeshPoliciesGenerator,
      PluginsGenerator,
      AIGatewayPoliciesGenerator,
      ReleaseMapLoader,
      SkillsGenerator,
      ReferencePagesGenerator,
      APIPagesGenerator,
      IndexGenerator,
      BrokenLinks,
      TagExplorer,
      MarkdownPagesGenerator,
      PageDataGenerator,
      RefirectsGenerator,
      SitemapGenerator
    ].freeze

    SKIP_KEYS = {
      ReleaseMapLoader => 'release_map_loader',
      IndexGenerator => 'indices',
      TagExplorer => 'explorer'
    }.freeze

    attr_reader :generators

    def initialize(config = {})
      super
      @generators = ORDER.map { |klass| klass.new(config) }
    end

    def generate(site)
      @generators.each do |generator|
        next if skip?(generator, site)

        start = Time.now
        generator.generate(site)
        Jekyll.logger.debug 'Generating:', "#{generator.class} finished in #{Time.now - start} seconds."
      end
    end

    private

    def skip?(generator, site)
      key = SKIP_KEYS[generator.class]

      !key.nil? && site.config.dig('skip', key)
    end
  end
end
