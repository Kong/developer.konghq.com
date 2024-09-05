require 'nokogiri'

Jekyll::Hooks.register :documents, :post_convert do |doc, payload|
  SectionWrapper::Base.make_for(doc).process
end

Jekyll::Hooks.register :pages, :post_convert do |page, payload|
  next if page.data['layout'] == 'landing_page'

  SectionWrapper::Base.make_for(page).process
end