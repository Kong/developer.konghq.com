# frozen_string_literal: true

require 'nokogiri'

Jekyll::Hooks.register :documents, :post_convert do |doc, _payload|
  SectionWrapper::Base.make_for(doc).process
end

Jekyll::Hooks.register :pages, :post_convert do |page, _payload|
  next unless %w[concept reference plugin policy].include?(page.data['content_type'])

  SectionWrapper::Base.make_for(page).process
end
