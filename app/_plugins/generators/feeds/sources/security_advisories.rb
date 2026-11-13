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
          string = value.to_s
          unless string.match?(/\A\d{4}-\d{2}-\d{2}\z/)
            raise ArgumentError,
                  "Invalid advisory.published '#{value}' in #{advisory_path}: expected a YYYY-MM-DD date"
          end

          date = Date.strptime(string, '%Y-%m-%d')
          Time.utc(date.year, date.month, date.day)
        rescue Date::Error => e
          raise ArgumentError,
                "Invalid advisory.published '#{value}' in #{advisory_path}: #{e.message}"
        end

        def advisory_path
          @doc&.relative_path || 'advisory'
        end
      end
    end
  end
end
