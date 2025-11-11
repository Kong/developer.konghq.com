# frozen_string_literal: true

require 'json'
require_relative '../../lib/site_accessor'

module Jekyll
  module Drops
    module Plugins
      class Schema < Liquid::Drop # rubocop:disable Style/Documentation
        include Jekyll::SiteAccessor

        def self.all(plugin:)
          plugin.releases.map do |release|
            new(release:, plugin: plugin)
          end
        end

        attr_reader :release

        def initialize(release:, plugin:) # rubocop:disable Lint/MissingSuper
          @release = release
          @plugin = plugin
        end

        def as_json
          schema
        end

        def compatible_protocols
          @compatible_protocols ||= schema.dig('properties', 'protocols', 'items', 'enum')
        end

        def required_fields
          @required_fields ||= schema.dig('properties', 'config', 'required')
        end

        private

        def plugin_slug
          @plugin_slug ||= @plugin.slug
        end

        def schema
          @schema ||= JSON.parse(File.read(file_path))
        end

        def file_path
          @file_path ||= if @plugin.third_party?
                           third_party_file_path
                         else
                           kong_schema_file_path
                         end
        end

        def kong_schema_file_path
          @kong_schema_file_path ||= File.join(
            site.config['plugin_schemas_path'],
            release.number,
            "#{plugin_slug.split('-').map(&:capitalize).join}.json"
          )
        end

        def third_party_file_path
          path = File.join(@plugin.folder, 'schema.json')

          unless File.exist?(path)
            raise ArgumentError,
                  "Missing `schema.json` file in #{@plugin.folder} for third-party plugin `#{plugin_slug}.`"
          end

          path
        end
      end
    end
  end
end
