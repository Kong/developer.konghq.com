require 'nokogiri'

Jekyll::Hooks.register :documents, :post_convert do |doc, payload|
  SectionWrapper::Base.make_for(doc).process
end

Jekyll::Hooks.register :pages, :post_convert do |page, payload|
  next unless ['concept', 'reference', 'plugin', 'plugin_reference'].include?(page.data['content_type'])

  SectionWrapper::Base.make_for(page).process
end
