# frozen_string_literal: true

module Jekyll
  class APIPagesGenerator < Generator
    SOURCE_FILE = '_data/konnect_oas_data.json'

    priority :low

    def generate(site)
      @site = site
      @site.data['ssg_api_pages'] = []

      Dir.glob(File.join(site.source, '_api/**/**/_index.md')).each do |file|
        frontmatter = page_frontmatter(file)
        product = page_product(frontmatter)

        raise ArgumentError, "Could not load API Product for #{file}" unless product

        Jekyll::APIPages::Product.new(product:, file:, site:, frontmatter:).generate_pages!
      end

      @site.pages << APIPages::Index.new(site:).to_jekyll_page

      set_konnect_product_ids
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
