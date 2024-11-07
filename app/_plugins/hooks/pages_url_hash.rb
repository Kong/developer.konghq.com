Jekyll::Hooks.register :site, :pre_render do |site|
  site.data['pages_urls'] = Set.new

  site.pages.each do |page|
    site.data['pages_urls'] << page.url if page.data['published'].nil? || page.data['published'] == true
  end

  site.documents.each do |doc|
    site.data['pages_urls'] << doc.url if doc.data['published'].nil? || doc.data['published'] == true
  end
end
