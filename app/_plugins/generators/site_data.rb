# frozen_string_literal: true

require 'json'

module Jekyll
  class SiteDataGenerator < Generator # rubocop:disable Style/Documentation
    priority :highest

    def generate(site)
      site.data['referenceable_fields'] = referenceable_fields(site)
      site.data['gateway_latest'] = site.data.dig('products', 'gateway', 'releases').detect { |r| r['latest'] }
      site.data['searchFilters'] = search_filters(site)
    end

    def referenceable_fields(site)
      @referenceable_fields ||= Dir.glob("#{files_path(site)}/*").each_with_object({}) do |file, h|
        release = file_path_to_release(file)
        h[release] = JSON.parse(File.read(file))
      end
    end

    def files_path(site)
      @files_path ||= site.config['plugin_referenceable_fields_path']
    end

    def file_path_to_release(file)
      File.basename(file).gsub('.x.json', '')
    end

    def search_filters(site)
      {
        products: site.data.fetch('products').map { |k, v| { label: v['name'], value: k } },
        tools: site.data.fetch('tools').map { |k, v| { label: v['name'], value: k } },
        works_on: site.data.dig('products', 'gateway', 'deployment_topologies').map do |t|
          { label: t['text'], value: t['slug'] }
        end
      }
    end
  end
end
