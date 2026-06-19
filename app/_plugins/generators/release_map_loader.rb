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
    end

    def set_major_banner_info(site, page)
      major_version = page.data['major_version'].first

      if major_version
        product_data = site.data.dig('products', major_version[0])
        page.data['cross_major_banner_info'] = {
          'product' => product_data['name'],
          'major_version' => MajorVersionResolver.process(product_data:, major: major_version[1])
        }
      end
    end

    def find_page_by_path!(relative_path, site)
      page = find_page(relative_path, site) || find_document(relative_path, site)

      raise ArgumentError, "No page found for #{relative_path}" if page.nil?

      page
    end

    def find_page(relative_path, site)
      site.pages.find { |p| p.relative_path == relative_path }
    end

    def find_document(relative_path, site)
      site.documents.find { |d| d.relative_path == relative_path }
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
