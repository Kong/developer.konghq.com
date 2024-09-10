# frozen_string_literal: true

module Jekyll
  class PageDataGenerator < Generator
    priority :low

    def generate(site)
      site.pages.each do |page|
        EditLink::Base.new(site:, page:).process
      end

      site.documents.each do |doc|
        EditLink::Base.new(site:, page: doc).process
      end
    end
  end
end