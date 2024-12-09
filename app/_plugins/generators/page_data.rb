# frozen_string_literal: true

module Jekyll
  class PageDataGenerator < Generator
    priority :lowest

    def generate(site)
      site.pages.each do |page|
        Data::EditLink::Base.new(site:, page:).process
        Data::Breadcrumbs.new(site:, page:).process
        Data::APISpecs.new(site:, page:).process
      end

      site.documents.each do |doc|
        Data::EditLink::Base.new(site:, page: doc).process
        Data::Prerequisites.new(site:, page: doc).process
        Data::Breadcrumbs.new(site:, page: doc).process
        Data::APISpecs.new(site:, page: doc).process
      end
    end
  end
end
