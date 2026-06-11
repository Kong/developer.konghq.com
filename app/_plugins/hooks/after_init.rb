# frozen_string_literal: true

Jekyll::Hooks.register :site, :after_init do |site|
  if Jekyll.env == 'test'
    site.config['skip'] = {}
    site.config['exclude'].delete('_references')
  end

  if Jekyll.env == 'development' && ENV['PAGE_PATHS']
    keep_prefixes = ['_', '.', 'assets']
    paths = ENV['PAGE_PATHS']&.split(',')&.map(&:strip)&.reject(&:empty?)
    url_segments = paths.map { |url| url.split('/').reject(&:empty?).first }
    subfolders = Dir.children(site.source).select do |entry|
      File.directory?(File.join(site.source, entry)) && keep_prefixes.none? { |prefix| entry.start_with?(prefix) }
    end

    # exclude folders that don't match the first segment of any of the urls
    site.config['exclude'].concat(subfolders.difference(url_segments))
  end
end
