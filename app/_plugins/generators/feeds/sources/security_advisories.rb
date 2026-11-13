# frozen_string_literal: true

require 'date'

module Jekyll
  module Feeds
    module Sources
      # Security advisories from the support collection, newest first.
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

        # Newest first; ties by title.
        def sort_key(item)
          [-item['date'].to_i, item['title'].to_s]
        end

        def item(doc)
          @doc = doc
          {
            'title' => doc.data['title'],
            'url' => doc.url,
            'date' => parse_date(doc.data.dig('advisory', 'published'))
          }
        end

        def parse_date(value)
          date = Date.parse(value.to_s)
          Time.utc(date.year, date.month, date.day)
        rescue ArgumentError => e
          raise ArgumentError,
                "Invalid advisory.published '#{value}' in #{@doc&.relative_path || 'advisory'}: #{e.message}"
        end
      end
    end
  end
end
