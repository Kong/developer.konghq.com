# frozen_string_literal: true

module Jekyll
  class PageDataGenerator < Generator # rubocop:disable Style/Documentation
    priority :lowest

    def generate(site)
      process_pages(site)
      process_docs(site)
    end

    def process_pages(site)
      site.pages.each do |page|
        Data::EditLink::Base.new(site:, page:).process
        Data::Breadcrumbs.new(site:, page:).process
        Data::APISpecs.new(site:, page:).process
        Data::Seo.new(site:, page:).process
        Data::SearchTags::Base.make_for(site:, page:).process
        Data::MinVersion.new(site:, page:).process
        Data::AddIndexToRelatedResources.new(site:, page:).process
      end
    end

    def process_docs(site) # rubocop:disable Metrics/AbcSize
      site.documents.each do |page|
        Data::EditLink::Base.new(site:, page:).process
        Data::Prerequisites.new(site:, page:).process
        Data::Breadcrumbs.new(site:, page:).process
        Data::APISpecs.new(site:, page:).process
        Data::Seo.new(site:, page:).process
        Data::SearchTags::Base.make_for(site:, page:).process
        Data::MinVersion.new(site:, page:).process
        Data::AddIndexToRelatedResources.new(site:, page:).process
      end
    end
  end
end
