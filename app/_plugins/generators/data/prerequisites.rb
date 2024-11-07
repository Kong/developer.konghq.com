# frozen_string_literal: true

module Jekyll
  module Data
    class Prerequisites
      attr_reader :site, :page

      def initialize(site:, page:)
        @site = site
        @page = page
      end

      def process
        @page.data['prerequisites'] = Jekyll::Drops::Prereqs.new(page:, site:)
      end
    end
  end
end