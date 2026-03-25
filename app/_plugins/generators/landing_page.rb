# frozen_string_literal: true

module Jekyll
  class LandingPagesGenerator < Jekyll::Generator
    priority :high

    def generate(site)
      current_mtimes = Utils::Incremental.collect_mtimes(
        File.join(site.source, '_landing_pages/**/*.yaml')
      )

      if Utils::Incremental.enabled? && @cached_mtimes && @cached_pages && !Utils::Incremental.mtimes_changed?(current_mtimes, @cached_mtimes)
        site.pages.concat(@cached_pages)
        Utils::Incremental.skip_regeneration(site, @cached_pages)
        Jekyll.logger.info 'IncrementalGen:', 'Skipped LandingPagesGenerator (sources unchanged)'
        return
      end

      before = site.pages.size
      Jekyll::LandingPages::Generator.run(site)

      @cached_pages = site.pages[before..]
      @cached_mtimes = current_mtimes
    end
  end
end
