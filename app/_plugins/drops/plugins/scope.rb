# frozen_string_literal: true

require 'json'
require_relative '../../lib/site_accessor'

module Jekyll
  module Drops
    module Plugins
      class Scope < Liquid::Drop
        include Jekyll::SiteAccessor
        extend Jekyll::SiteAccessor

        def self.all(release:)
          site.data.fetch('kong_plugins').map do |_slug, plugin|
            new(release:, plugin:)
          end
        end

        def initialize(plugin:, release:)
          @plugin = plugin
          @release = release
        end

        def scopes
          @scopes ||= site.data.dig('plugins', 'tables', 'scopes', 'columns').map do |c|
            c.fetch('key')
          end
        end

        def values
          @values ||= if schema
                        scopes.each_with_object({}) { |s, h| h[s] = value(s) }
                      else
                        # TODO: do we want to include plugins that aren't available
                        # for a specific release?
                        scopes.each_with_object({}) { |s, h| h[s] = 'N/A' }
                      end
        end

        def title
          @title ||= @plugin.data['name']
        end

        def url
          @url ||= @plugin.data['overview_url']
        end

        def [](key)
          key = key.to_s
          if respond_to?(key)
            public_send(key)
          else
            values[key]
          end
        end

        private

        def schema
          @schema ||= @plugin.data.fetch('plugin').schemas.detect do |s|
            s.release == @release
          end
        end

        def value(field)
          if field == 'global'
            true
          else
            !!schema.as_json.dig('properties', field)
          end
        end
      end
    end
  end
end
