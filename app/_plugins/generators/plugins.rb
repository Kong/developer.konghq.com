# frozen_string_literal: true

module Jekyll
  class PluginsGenerator < Jekyll::Generator
    priority :high

    PLUGINS_FOLDER = '_kong_plugins'

    def generate(site)
      site.data['kong_plugins'] ||= {}

      unless Utils::Incremental.enabled?
        Jekyll::PluginPages::Generator.run(site)
        return
      end

      @plugin_cache ||= {}
      schema_mtimes = Utils::Incremental.collect_mtimes(
        File.join(site.config['plugin_schemas_path'], '**/*')
      )
      schemas_changed = @cached_schema_mtimes.nil? || Utils::Incremental.mtimes_changed?(schema_mtimes, @cached_schema_mtimes)
      @plugin_cache.clear if schemas_changed

      generator = Jekyll::PluginPages::Generator.new(site)
      skipped = Utils::Incremental.generate_items_with_cache(
        site, cache: @plugin_cache, parent_folder: PLUGINS_FOLDER, data_key: 'kong_plugins'
      ) do |slug, folder|
        plugin = Jekyll::PluginPages::Plugin.new(folder:, slug:)
        generator.generate_pages(plugin)
      end

      @cached_schema_mtimes = schema_mtimes
      Jekyll.logger.info 'IncrementalGen:', "PluginsGenerator: #{skipped} plugins restored from cache" if skipped.positive?
    end
  end
end
