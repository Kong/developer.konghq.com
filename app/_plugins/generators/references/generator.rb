# frozen_string_literal: true

module Jekyll
  module ReferencePages
    class Generator
      def self.run(site)
        new(site).run
      end

      attr_reader :site

      def initialize(site)
        @site = site
      end

      def run
        version_pages!
        version_docs!
      end

      def version_pages!
        versioned_pages = []
        site.pages.each do |page|
          next if page.data['content_type'] != 'reference'
          # TODO: handle auto_generated pages
          next if page.data['auto_generated']

          versioned_pages.concat(Versioner.new(site:, page:).process)
        end
        site.pages.concat(versioned_pages)
      end

      def version_docs!
        versioned_pages = []
        site.documents.each do |doc|
          next if doc.data['content_type'] != 'reference'

          versioned_pages.concat(Versioner.new(site:, page: doc).process)
        end
        # Create pages instead of docs, versioned pages shouldn't be part
        # of the collection.
        site.pages.concat(versioned_pages)
      end
    end
  end
end
