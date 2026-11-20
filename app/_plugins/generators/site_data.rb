# frozen_string_literal: true

require 'json'
require 'active_support/inflector'

module Jekyll
  class SiteDataGenerator < Generator # rubocop:disable Style/Documentation
    priority :highest

    def generate(site)
      site.data['searchFilters'] = search_filters(site)
      site.data['searchSources'] = site.data.dig('search', 'sources')

      product_latest_release(site)
      tools_latest_release(site)
      load_blocked_user_agents(site)
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

    def product_latest_release(site)
      site.data['products'].each_key do |slug|
        releases = site.data.dig('products', slug, 'releases')
        next if releases.nil?

        key = slug.gsub('-', '_')
        site.data["#{key}_latest"] = releases.detect { |r| r['latest'] }
        site.data["#{key}_releases"] = releases
      end
    end

    def tools_latest_release(site)
      site.data['tools'].map do |tool, values|
        releases = values.fetch('releases', [])
        next if releases.empty?

        site.data["#{tool.underscore}_latest"] = releases.detect { |r| r['latest'] }
      end
    end

    def load_blocked_user_agents(site)
      site.data['blocked_user_agents'] = YAML.load_file(File.expand_path('app/_config/blocked_user_agents.yml'))
    end
  end
end
