# frozen_string_literal: true

require 'json'
require 'date'
require 'kramdown'

module Jekyll
  module Drops
    module ChangelogFeed
      # Builds feed entries for changelog sources whose underlying data is
      # structured JSON: Gateway (app/_data/changelogs/gateway.json) and
      # individual plugins (app/_kong_plugins/<slug>/changelog.json).
      #
      # Dates are resolved exclusively from app/_data/changelogs/_dates.yml.
      # Versions without a resolved date are skipped, per RSS spec.
      class SourceStructured
        # Entry shape returned by #entries:
        #   {
        #     'title'        => 'Kong Gateway 3.10.0.11',
        #     'link'         => '/gateway/changelog/#3-10-0-11',
        #     'guid'         => 'gateway/3.10.0.11',
        #     'date'         => <Time>,
        #     'categories'   => ['Gateway'],
        #     'content_html' => '<p>...</p>'
        #   }
        attr_reader :entries

        def self.gateway(site, feed_config)
          drop = Jekyll::Drops::GatewayChangelog.new(site: site)
          dates = dates_map(site, feed_config['dates_key'])
          page_url = feed_config['page_url']

          entries = drop.versions.map do |version|
            date = dates[version.number]
            next nil unless date

            {
              'title'        => "Kong Gateway #{version.number}",
              'link'         => "#{page_url}##{anchor(version.number)}",
              'guid'         => "gateway/#{version.number}",
              'date'         => to_time(date),
              'categories'   => ['Gateway'],
              'content_html' => render_gateway_version(version)
            }
          end.compact

          new(entries)
        end

        def self.plugin(site, slug, plugin_changelog_path, page_url)
          plugin_dates = site.data.dig('changelogs', '_dates', 'plugins', slug) || {}
          raw = JSON.parse(File.read(plugin_changelog_path))
          entries = raw.map do |version_key, version_entries|
            date = plugin_dates[version_key]
            next nil unless date

            {
              'title'        => "#{slug} #{version_key}",
              'link'         => "#{page_url}##{anchor(version_key)}",
              'guid'         => "plugins/#{slug}/#{version_key}",
              'date'         => to_time(date),
              'categories'   => [slug],
              'content_html' => render_entries(version_entries)
            }
          end.compact.sort_by { |e| e['date'] }.reverse

          new(entries)
        end

        def initialize(entries)
          @entries = entries
        end

        # -------- internals --------

        def self.dates_map(site, key)
          site.data.dig('changelogs', '_dates', key) || {}
        end

        def self.anchor(version)
          version.to_s.gsub('.', '-')
        end

        def self.to_time(value)
          case value
          when Time, DateTime then value.to_time
          when Date           then value.to_time
          else                     Time.parse(value.to_s)
          end
        end

        def self.render_entries(version_entries)
          # version_entries is an array of { message:, type:, scope:, ... } hashes.
          grouped = version_entries.group_by { |e| e['type'] || 'other' }
          html = +''
          grouped.each do |type, type_entries|
            html << "<h3>#{escape(type.to_s.capitalize)}</h3>\n<ul>\n"
            type_entries.each do |e|
              html << "<li>#{markdown_to_html(e['message'].to_s)}</li>\n"
            end
            html << "</ul>\n"
          end
          html
        end

        def self.render_gateway_version(version)
          # version.entries_by_type returns { 'feature' => Entries, ... }
          html = +''
          version.entries_by_type.each do |type, entries_drop|
            html << "<h3>#{escape(type.to_s.capitalize)}</h3>\n"
            entries_drop.by_scope.each do |scope, scope_entries|
              html << "<h4>#{escape(scope.to_s)}</h4>\n<ul>\n"
              if scope == 'Plugin'
                scope_entries.each do |plugin_label, plugin_entries|
                  if plugin_label == Jekyll::Drops::GatewayChangelog::Entries::NO_LINK
                    plugin_entries.each { |e| html << "<li>#{markdown_to_html(e['message'])}</li>\n" }
                  else
                    html << "<li>#{markdown_to_html(plugin_label)}\n<ul>\n"
                    plugin_entries.each { |e| html << "<li>#{markdown_to_html(e['message'])}</li>\n" }
                    html << "</ul>\n</li>\n"
                  end
                end
              else
                scope_entries.each { |e| html << "<li>#{markdown_to_html(e['message'])}</li>\n" }
              end
              html << "</ul>\n"
            end
          end
          html
        end

        def self.markdown_to_html(text)
          Kramdown::Document.new(text.to_s.strip, input: 'GFM').to_html
        end

        def self.escape(s)
          s.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
        end
      end
    end
  end
end
