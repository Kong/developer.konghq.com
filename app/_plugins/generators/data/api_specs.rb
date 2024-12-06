# frozen_string_literal: true

module Jekyll
  module Data
    class APISpecs
      attr_reader :site, :page

      def initialize(site:, page:)
        @site = site
        @page = page
      end

      def process
        return nil unless @page.data['api_specs']

        @page.data['api_specs'] = api_specs
      end

      private

      def api_specs
        @page.data['api_specs'].map do |spec|
          api_spec = api_page(spec)
          raise ArgumentError, "There's no API in app/_api/ that matches #{spec}" unless api_spec

          Drops::APISpecLink.new(api_spec:, site:)
        end
      end

      def api_page(spec)
        site
          .data
          .fetch('ssg_api_pages', [])
          .detect { |page| page.data['base_url'] == "/api/#{spec}/" }
      end
    end
  end
end
