# frozen_string_literal: true

module Jekyll
  class PluginsGenerator < Jekyll::Generator
    priority :high

    PLUGINS_FOLDER = '_kong_plugins'

    def generate(site) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
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

      skipped = 0
      generator = Jekyll::PluginPages::Generator.new(site)

      Dir.glob(File.join(site.source, "#{PLUGINS_FOLDER}/*/")).each do |folder|
        slug = folder.gsub("#{site.source}/#{PLUGINS_FOLDER}/", '').chomp('/')
        current_mtimes = Utils::Incremental.collect_mtimes("#{folder}**/*")
        cached = @plugin_cache[slug]

        if cached && !Utils::Incremental.mtimes_changed?(current_mtimes, cached[:mtimes])
          site.pages.concat(cached[:pages])
          Utils::Incremental.skip_regeneration(site, cached[:pages])
          site.data['kong_plugins'][slug] = cached[:data]
          skipped += 1
        else
          before = site.pages.size
          plugin = Jekyll::PluginPages::Plugin.new(folder:, slug:)
          generator.generate_pages(plugin)
          new_pages = site.pages[before..]
          @plugin_cache[slug] = { mtimes: current_mtimes, pages: new_pages, data: site.data['kong_plugins'][slug] }
        end
      end

      @cached_schema_mtimes = schema_mtimes
      Jekyll.logger.info 'IncrementalGen:', "PluginsGenerator: #{skipped} plugins restored from cache" if skipped.positive?
    end
  end
end
