# frozen_string_literal: true

require_relative '../lib/build_filter'

class ReleaseMap
  def self.load_all(site, build_filter: Jekyll::BuildFilter.current)
    releases_dir = File.join(site.source, '_config', 'releases')
    return {} unless Dir.exist?(releases_dir)

    products = build_filter.filtered? ? build_filter.products : []

    Dir.glob(File.join(releases_dir, '**', '*.yml')).sort.each_with_object({}) do |path, entries|
      next unless products.empty? || products.include?(product_for(releases_dir, path))

      entries.merge!(YAML.safe_load(File.read(path)) || {})
    end
  end

  def self.product_for(releases_dir, path)
    path.delete_prefix("#{releases_dir}/").split('/').first
  end
  private_class_method :product_for
end
