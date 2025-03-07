# frozen_string_literal: true

Jekyll::Hooks.register :site, :pre_render do |site|
  site.data['pages_urls'] = Set.new
  site.data['tags'] = Set.new

  site.pages.each do |page|
    site.data['pages_urls'] << page.url if page.data['published'].nil? || page.data['published'] == true
    site.data['tags'].merge(page.data['tags']) if page.data['tags']
  end

  site.documents.each do |doc|
    site.data['pages_urls'] << doc.url if doc.data['published'].nil? || doc.data['published'] == true
    site.data['tags'].merge(doc.data['tags']) if doc.data['tags']
  end

  site.data['searchFilters'][:tags] = site.data['tags'].to_a.sort
end
