# frozen_string_literal: true

require_relative '../../lib/site_accessor'

module Jekyll
  module Drops
    module Plugins
      module Tabular # rubocop:disable Style/Documentation
        include Jekyll::SiteAccessor

        def self.included(base)
          base.extend(ClassMethods)
          base.extend(Jekyll::SiteAccessor)
        end

        module ClassMethods # rubocop:disable Style/Documentation
          def all(release:)
            site.data
                .fetch('kong_plugins')
                .reject { |_, p| p.data['third_party'] }
                .map { |_, plugin| new(release:, plugin:) }
                .reject { |p| p.json_schema.nil? }
          end
        end

        def initialize(plugin:, release:)
          @plugin = plugin
          @release = release
        end

        def values
          @values ||= if json_schema
                        columns.each_with_object({}) { |s, h| h[s] = value(s) }
                      else
                        # TODO: do we want to include plugins that aren't available
                        # for a specific release?
                        columns.each_with_object({}) { |s, h| h[s] = 'N/A' }
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

        def schema
          @schema ||= @plugin.data.fetch('plugin').schemas.detect do |s|
            s.release == @release
          end
        end

        def json_schema
          @json_schema ||= schema&.as_json
        end
      end
    end
  end
end
