# frozen_string_literal: true

Jekyll::Hooks.register :site, :pre_render do |site|
  site.data['pages_urls'] = Set.new
  site.data['act_as_plugins'] = {}

  site.pages.each do |page|
    site.data['pages_urls'] << page.url if page.data['published'].nil? || page.data['published'] == true

    next unless page.data['act_as_plugin']

    slug = page.dir.split('/').last

    # add custom_name, name is the actual file name in jekyll
    page.data['act_as_plugin_name'] = page.data['name']
    site.data['act_as_plugins'][slug] = page
  end

  site.documents.each do |doc|
    site.data['pages_urls'] << doc.url if doc.data['published'].nil? || doc.data['published'] == true

    next unless doc.data['act_as_plugin']

    slug = doc.basename_without_ext
    site.data['act_as_plugins'][slug] = doc
  end

  site.data['searchFilters'][:kong_plugins] = site.data.fetch('kong_plugins', {}).map do |slug, plugin|
    { label: plugin.data.fetch('name'), value: slug }
  end
  site.data['searchFilters'][:tags] = site.data.dig('schemas', 'frontmatter', 'tags', 'enum').sort.map do |t|
    { label: t, value: t }
  end
end
