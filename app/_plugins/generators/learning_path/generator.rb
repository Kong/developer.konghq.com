# frozen_string_literal: true

require_relative 'page'
require_relative 'step_page'
require_relative 'product_index_page'
require_relative 'persona_index_page'

module Jekyll
  module LearningPath
    class Generator
      def self.run(site)
        files = Dir.glob(File.join(site.source, '_learning-paths/**/*.yaml'))
        return if files.empty?

        # Ensure site.data['series'] exists so we can register learning-path series entries.
        site.data['series'] ||= {}

        overview_pages = files.map do |file|
          page = Jekyll::LearningPath::Page.new(site, file)
          site.pages << page

          steps = page.source_data['steps'] || []
          next page if steps.empty?

          series_id = derive_series_id(page.url)

          # Register this learning path in the global series registry so the
          # existing Jekyll::Data::Series generator can resolve series metadata
          # without raising "Could not read series meta from _data/series.yml".
          site.data['series'][series_id] = {
            'title' => page.data['title'],
            'url' => page.url
          }

          steps.each_with_index do |step_data, idx|
            site.pages << Jekyll::LearningPath::StepPage.new(
              site, step_data, page.source_data, idx + 1, series_id, page.url
            )
          end

          page
        end

        # Per-product index pages: group by each product the path is tagged with.
        group_pages(overview_pages, 'products').each do |product, pages|
          site.pages << Jekyll::LearningPath::ProductIndexPage.new(site, product, pages)
        end

        # Per-persona index pages: group by each persona the path is tagged with.
        group_pages(overview_pages, 'personas').each do |persona, pages|
          site.pages << Jekyll::LearningPath::PersonaIndexPage.new(site, persona, pages)
        end
      end

      # Derives a stable, unique series ID from the overview page URL.
      # e.g. "/learning-paths/gateway/intro-to-kong-gateway/" => "learning-paths-gateway-intro-to-kong-gateway"
      def self.derive_series_id(url)
        url.gsub('/', '-').gsub(/^-|-$/, '')
      end
      private_class_method :derive_series_id

      def self.group_pages(overview_pages, field)
        overview_pages.each_with_object(Hash.new { |h, k| h[k] = [] }) do |page, hash|
          Array(page.data[field]).each { |key| hash[key] << page }
        end
      end
      private_class_method :group_pages
    end
  end
end
