# frozen_string_literal: true

Jekyll::Hooks.register :site, :pre_render do |site|
  site.data['pages_urls'] = Set.new
  site.data['tags'] = Set.new
  site.data['act_as_plugins'] = {}

  site.pages.each do |page|
    site.data['pages_urls'] << page.url if page.data['published'].nil? || page.data['published'] == true
    site.data['tags'].merge(page.data['tags']) if page.data['tags']

    next unless page.data['act_as_plugin']

    slug = page.dir.split('/').last
    site.data['act_as_plugins'][slug] = page
  end

  site.documents.each do |doc|
    site.data['pages_urls'] << doc.url if doc.data['published'].nil? || doc.data['published'] == true
    site.data['tags'].merge(doc.data['tags']) if doc.data['tags']

    next unless doc.data['act_as_plugin']

    slug = doc.basename_without_ext
    site.data['act_as_plugins'][slug] = doc
  end

  site.data['searchFilters'][:tags] = site.data['tags'].to_a.sort.map { |t| { label: t, value: t } }
end
