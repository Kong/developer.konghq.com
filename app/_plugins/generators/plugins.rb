# frozen_string_literal: true

module Jekyll
  class PluginsGenerator < Jekyll::Generator
    priority :high

    def generate(site)
      current_mtimes = Utils::Incremental.collect_mtimes(
        File.join(site.source, '_kong_plugins/**/*'),
        File.join(site.config['plugin_schemas_path'], '**/*')
      )

      if Utils::Incremental.enabled? && @cached_mtimes && @cached_pages && !Utils::Incremental.mtimes_changed?(current_mtimes, @cached_mtimes)
        site.pages.concat(@cached_pages)
        Utils::Incremental.skip_regeneration(site, @cached_pages)
        site.data['kong_plugins'] = @cached_kong_plugins
        Jekyll.logger.info 'IncrementalGen:', 'Skipped PluginsGenerator (sources unchanged)'
        return
      end

      site.data['kong_plugins'] ||= {}

      before = site.pages.size
      Jekyll::PluginPages::Generator.run(site)

      @cached_pages = site.pages[before..]
      @cached_kong_plugins = site.data['kong_plugins'].dup
      @cached_mtimes = current_mtimes
    end
  end
end
