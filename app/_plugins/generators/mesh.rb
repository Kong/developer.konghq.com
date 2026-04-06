# frozen_string_literal: true

module Jekyll
  class MeshGenerator < Jekyll::Generator # rubocop:disable Style/Documentation
    priority :high

    def generate(site)
      return if site.config.dig('skip', 'mesh')

      current_mtimes = Utils::Incremental.collect_mtimes(
        File.join(site.source, '_data/kuma_to_mesh/config.yaml'),
        File.join(site.source, '.repos/kuma/app/_src/**/*.md')
      )

      if Utils::Incremental.enabled? && @cached_mtimes && @cached_pages && !Utils::Incremental.mtimes_changed?(current_mtimes, @cached_mtimes)
        site.pages.concat(@cached_pages)
        Utils::Incremental.skip_regeneration(site, @cached_pages)
        Jekyll.logger.info 'IncrementalGen:', 'Skipped MeshGenerator (sources unchanged)'
        return
      end

      before = site.pages.size

      site.data.dig('kuma_to_mesh', 'config').fetch('pages', []).each do |page_config|
        page = KumatoMesh::Page.new(site:, page_config:).to_jekyll_page
        KumatoMesh::Converter.new(page).process
        site.pages << page
      end

      @cached_pages = site.pages[before..]
      @cached_mtimes = current_mtimes
    end
  end
end
