# frozen_string_literal: true

require 'json'
require 'active_support/inflector'

module Jekyll
  class SiteDataGenerator < Generator # rubocop:disable Style/Documentation
    priority :highest

    def generate(site)
      site.data['referenceable_fields'] = plugins_data(site, 'plugin_referenceable_fields_path')
      site.data['plugin_priorities'] = plugins_data(site, 'plugin_priorities_path')
      site.data['searchFilters'] = search_filters(site)
      site.data['searchSources'] = site.data.dig('search', 'sources')

      product_latest_release(site)
      tools_latest_release(site)
    end

    def plugins_data(site, key)
      Dir.glob("#{files_path(site, key)}/*").each_with_object({}) do |file, h|
        release = file_path_to_release(file)
        h[release] = JSON.parse(File.read(file))
      end
    end

    def files_path(site, key)
      site.config[key]
    end

    def file_path_to_release(file)
      File.basename(file).gsub('.x.json', '')
    end

    def search_filters(site)
      {
        products: site.data.fetch('products').map { |k, v| { label: v['name'], value: k } },
        tools: site.data.fetch('tools').except('kic', 'operator').map { |k, v| { label: v['name'], value: k } },
        works_on: site.data.dig('products', 'gateway', 'deployment_topologies').map do |t|
          { label: t['text'], value: t['slug'] }
        end
      }
    end

    def product_latest_release(site) # rubocop:disable Metrics/AbcSize
      products = site.data['products'].map do |p|
        p[0].gsub('-', '_')
      end

      products.each do |product|
        releases = site.data.dig('products', product, 'releases')
        next if releases.nil?

        site.data["#{product}_latest"] = releases.detect { |r| r['latest'] }
        site.data["#{product}_releases"] = releases
      end
    end

    def tools_latest_release(site)
      site.data['tools'].map do |tool, values|
        releases = values.fetch('releases', [])
        next if releases.empty?

        site.data["#{tool.underscore}_latest"] = releases.detect { |r| r['latest'] }
      end
    end
  end
end
