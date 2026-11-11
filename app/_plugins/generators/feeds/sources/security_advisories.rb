# frozen_string_literal: true

require 'date'

module Jekyll
  module Feeds
    module Sources
      # Security advisories from the support collection, newest first, undated last.
      class SecurityAdvisories
        def self.items(site)
          new(site).items
        end

        def initialize(site)
          @site = site
        end

        def items
          advisories.map { |doc| item(doc) }.sort_by { |i| sort_key(i) }
        end

        private

        def advisories
          docs = @site.collections['support']&.docs || []
          docs.select { |doc| doc.data['advisory'] }
        end

        # Dated items first, newest first; undated last; ties by title.
        def sort_key(item)
          date = item['date']
          [date ? 0 : 1, date ? -date.to_i : 0, item['title'].to_s]
        end

        def item(doc)
          {
            'title' => doc.data['title'],
            'url' => doc.url,
            'date' => parse_date(doc.data.dig('advisory', 'published'))
          }
        end

        def parse_date(value)
          return if value.nil? || value.to_s.strip.empty?

          date = value.respond_to?(:to_time) && !value.is_a?(String) ? value.to_time : Date.parse(value.to_s)
          Time.utc(date.year, date.month, date.day)
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
