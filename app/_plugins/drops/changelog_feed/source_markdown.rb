# frozen_string_literal: true

require 'date'
require 'kramdown'

module Jekyll
  module Drops
    module ChangelogFeed
      # Builds feed entries for changelog sources whose underlying data is
      # Markdown with `## VERSION` headings (Mesh, Operator, Event Gateway).
      # The body between one heading and the next becomes the entry content;
      # dates come exclusively from app/_data/changelogs/_dates.yml.
      class SourceMarkdown
        attr_reader :entries

        def self.from_config(site, feed_config)
          file = File.join(site.source || Dir.pwd, '..', feed_config['file'])
          file = File.expand_path(file)
          unless File.exist?(file)
            # Fall back to repo-root-relative resolution if site.source differs.
            file = File.expand_path(feed_config['file'])
          end

          dates = site.data.dig('changelogs', '_dates', feed_config['dates_key']) || {}
          page_url = feed_config['page_url']
          product_label = feed_config['title']

          entries = parse_sections(file).map do |section|
            date = dates[section[:version]]
            next nil unless date

            {
              'title'        => "#{product_label.sub(/\s*changelog\s*$/i, '')} #{section[:version]}",
              'link'         => "#{page_url}##{anchor(section[:version])}",
              'guid'         => "#{feed_config['dates_key']}/#{section[:version]}",
              'date'         => to_time(date),
              'categories'   => [feed_config['dates_key']],
              'content_html' => Kramdown::Document.new(section[:body], input: 'GFM').to_html
            }
          end.compact.sort_by { |e| e['date'] }.reverse

          new(entries)
        end

        def initialize(entries)
          @entries = entries
        end

        # -------- internals --------

        def self.parse_sections(file_path)
          sections = []
          current = nil
          File.foreach(file_path) do |line|
            if (m = line.match(/^##\s+([^\s#].*)$/))
              sections << current if current
              current = { version: m[1].strip, body: +'' }
            elsif current
              current[:body] << line
            end
          end
          sections << current if current
          sections
        end

        def self.anchor(version)
          version.to_s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
        end

        def self.to_time(value)
          case value
          when Time, DateTime then value.to_time
          when Date           then value.to_time
          else                     Time.parse(value.to_s)
          end
        end
      end
    end
  end
end
