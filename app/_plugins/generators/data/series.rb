# frozen_string_literal: true

module Jekyll
  module Data
    class Series # rubocop:disable Style/Documentation
      attr_reader :site

      def initialize(site:)
        @site = site

        @series = {}
      end

      def process # rubocop:disable Metrics/MethodLength
        build_series_list!

        # Add series data to each page and document
        @site.pages.each do |page|
          set_series_items!(page)
          set_prerequisites!(page)
          set_next_prev!(page)
          set_cleanup!(page)
        end

        @site.documents.each do |page|
          set_series_items!(page)
          set_prerequisites!(page)
          set_next_prev!(page)
          set_cleanup!(page)
        end
      end

      private

      def set_series_items!(page)
        return unless page.data['series']

        series_id = page.data['series']['id']
        page.data['series']['items'] = @series[series_id]
      end

      def set_prerequisites!(page) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        return unless page.data['series']

        page.data['prereqs'] = page.data['prereqs'] || {}

        previous_page = page.data['series']['items'].find do |item|
          item.data['series']['position'] == page.data['series']['position'] - 1
        end

        return unless previous_page

        series_meta = @site.data['series'][page.data['series']['id']]

        unless series_meta
          raise "Could not read series meta from app/_data/series.yml with key #{page.data['series']['id']}"
        end

        page.data['prereqs']['inline'] ||= []
        page.data['prereqs']['inline'] << {
          'position' => 'before',
          'title' => 'Series Prerequisites',
          'content' => <<~HEREDOC.strip
            This page is part of the [**#{series_meta['title']}**](#{series_meta['url']}) series.

            Complete the previous page, [**#{previous_page.data['title']}**](#{previous_page.url}) before completing this page.
          HEREDOC
        }
      end

      def set_next_prev!(page) # rubocop:disable Metrics/AbcSize
        return unless page.data['series']

        page.data['navigation'] = {}

        page.data['navigation']['prev'] = page.data['series']['items'].find do |item|
          item.data['series']['position'] == page.data['series']['position'] + -1
        end

        page.data['navigation']['next'] = page.data['series']['items'].find do |item|
          item.data['series']['position'] == page.data['series']['position'] + 1
        end
      end

      def set_cleanup!(page)
        return unless page.data['series']

        page.data['cleanup'] = nil
      end

      def add_series_item(id, page)
        @series[id] ||= []
        @series[id] << page
      end

      def build_series_list! # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        @site.pages.each do |page|
          next unless page.data['series']

          add_series_item(page.data['series']['id'], page)
        end

        @site.documents.each do |page|
          next unless page.data['series']

          add_series_item(page.data['series']['id'], page)
        end

        @series.transform_values! do |items|
          items.sort_by { |item| item.data['series']['position'] }
        end
      end

      def find_page_by_url(url)
        site.pages.detect { |p| p.url == url } ||
          site.documents.detect { |d| d.url == url }
      end
    end
  end
end
