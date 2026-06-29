# frozen_string_literal: true

require_relative '../services/release_map'

module Jekyll
  class ReleaseMapLoader < Generator
    priority :high

    def generate(site)
      ReleaseMap.load_all(site).each do |source_path, config|
        validate_status!(source_path, config)
        process_page(source_path, config, site)
      end
    end

    private

    def process_page(source_path, config, site)
      relative_path = source_path.sub(%r{^app/}, '')
      page = find_page_by_path!(relative_path, site)

      page.data['canonical_url'] = config['canonical_url'] if config['canonical_url']

      set_major_banner_info(site, page)
      set_previous_major_urls(site, page)
    end

    def set_major_banner_info(site, page)
      major_version = page.data['major_version'].first

      return unless major_version

      product = product_data(site, major_version)
      page.data['cross_major_banner_info'] = {
        'product' => product.product_name,
        'major_version' => product.major_version
      }
    end

    def set_previous_major_urls(site, page)
      return unless page.data['canonical_url']

      canonical_page = find_page_or_doc_by_url(page.data['canonical_url'], site)
      return unless canonical_page

      major_version = page.data['major_version'].first
      product = product_data(site, major_version)

      canonical_page.data['previous_major_urls'] ||= {}
      canonical_page.data['previous_major_urls'][product.major_version] ||= []
      canonical_page.data['previous_major_urls'][product.major_version] << page.url
    end

    def find_page_by_path!(relative_path, site)
      page = find_page(relative_path, site) || find_document(relative_path, site)

      raise ArgumentError, "No page found for #{relative_path}" if page.nil?

      page
    end

    def product_data(site, major_version)
      data = site.data.dig('products', major_version[0])
      OpenStruct.new(
        product_name: data['name'],
        major_version: MajorVersionResolver.process(product_data: data, major: major_version[1])
      )
    end

    def find_page(relative_path, site)
      site.pages.find { |p| p.relative_path == relative_path }
    end

    def find_document(relative_path, site)
      site.documents.find { |d| d.relative_path == relative_path }
    end

    def find_page_or_doc_by_url(url, site)
      site.pages.find { |p| p.url == url } || site.documents.find { |d| d.url == url }
    end

    def validate_status!(source_path, config)
      if config['status']
        raise ArgumentError, "invalid status: #{config['status']} for #{source_path}" if config['status'] != 'pending'

        Jekyll.logger.warn 'ReleaseMapLoader:', "Pending entry #{source_path}."

      elsif config['canonical_url'].nil?
        raise ArgumentError, "blank canonical_url for non-pending entry #{source_path}."
      end
    end
  end
end
