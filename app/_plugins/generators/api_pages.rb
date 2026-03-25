# frozen_string_literal: true

module Jekyll
  class APIPagesGenerator < Generator
    SOURCE_FILE = '_data/konnect_oas_data.json'

    priority :low

    def generate(site)
      @site = site

      current_mtimes = Utils::Incremental.collect_mtimes(
        File.join(site.source, '_api/**/**/_index.md'),
        File.join(site.source, SOURCE_FILE)
      )

      if Utils::Incremental.enabled? && @cached_mtimes && @cached_pages && !Utils::Incremental.mtimes_changed?(current_mtimes, @cached_mtimes)
        site.pages.concat(@cached_pages)
        Utils::Incremental.skip_regeneration(site, @cached_pages)
        @site.data['ssg_api_pages'] = @cached_ssg_api_pages
        @site.data['konnect_product_ids'] = @cached_konnect_product_ids
        Jekyll.logger.info 'IncrementalGen:', 'Skipped APIPagesGenerator (sources unchanged)'
        return
      end

      @site.data['ssg_api_pages'] = []
      @products = nil

      before = site.pages.size

      Dir.glob(File.join(site.source, '_api/**/**/_index.md')).each do |file|
        frontmatter = page_frontmatter(file)
        product = page_product(frontmatter)

        raise ArgumentError, "Could not load API Product for #{file}" unless product

        Jekyll::APIPages::Product.new(product:, file:, site:, frontmatter:).generate_pages!
      end

      @site.pages << APIPages::Index.new(site:).to_jekyll_page

      set_konnect_product_ids

      @cached_pages = site.pages[before..]
      @cached_ssg_api_pages = @site.data['ssg_api_pages'].dup
      @cached_konnect_product_ids = @site.data['konnect_product_ids'].dup
      @cached_mtimes = current_mtimes
    end

    private

    def page_frontmatter(page)
      Utils::MarkdownParser.new(File.read(page)).frontmatter
    end

    def page_product(frontmatter)
      product_id = frontmatter.fetch('konnect_product_id')

      products.detect { |p| p['id'] == product_id }
    end

    def products
      @products ||= JSON.parse(File.read(File.join(@site.source, SOURCE_FILE)))
    end

    def set_konnect_product_ids
      @site.data['konnect_product_ids'] = {}
      @site.data['ssg_api_pages'].each do |api|
        @site.data['konnect_product_ids'][api.data['base_url']] = api.data.fetch('konnect_product_id')
      end
    end
  end
end
