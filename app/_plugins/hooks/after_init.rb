# frozen_string_literal: true

require_relative '../lib/build_filter'

Jekyll::Hooks.register :site, :after_init do |site|
  if Jekyll.env == 'test'
    site.config['skip'] = {}
    site.config['exclude'].delete('_references')
  end

  filter = Jekyll::BuildFilter.current

  if Jekyll.env == 'development' && filter.page_paths.any?
    keep_prefixes = ['_', '.', 'assets']
    url_segments = filter.page_paths.map { |url| url.split('/').reject(&:empty?).first }
    subfolders = Dir.children(site.source).select do |entry|
      File.directory?(File.join(site.source, entry)) && keep_prefixes.none? { |prefix| entry.start_with?(prefix) }
    end

    # exclude folders that don't match the first segment of any of the urls
    site.config['exclude'].concat(subfolders.difference(url_segments))
  end
end
