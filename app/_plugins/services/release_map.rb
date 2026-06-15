# frozen_string_literal: true

class ReleaseMap
  def self.load_all(site)
    releases_dir = File.join(site.source, '_config', 'releases')
    return {} unless Dir.exist?(releases_dir)

    Dir.glob(File.join(releases_dir, '**', '*.yml')).sort.each_with_object({}) do |path, entries|
      entries.merge!(YAML.safe_load(File.read(path)) || {})
    end
  end
end
