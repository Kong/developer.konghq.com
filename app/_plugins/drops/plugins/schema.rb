# frozen_string_literal: true

require 'json'

module Jekyll
  module Drops
    module Plugins
      class Schema < Liquid::Drop # rubocop:disable Style/Documentation
        SCHEMAS_BASE = File.expand_path('../../../_schemas/gateway/plugins', __dir__).freeze

        FILE_INDEX = Hash.new do |h, dir|
          h[dir] = Dir.glob(File.join(dir, '*.json'))
                      .to_h { |f| [File.basename(f).downcase, f] }
                      .freeze
        end

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
          @file_path ||= @plugin.third_party? ? third_party_file_path : kong_schema_file_path
        end

        def kong_schema_file_path
          @kong_schema_file_path ||= begin
            dir = File.join(SCHEMAS_BASE, release.number)
            FILE_INDEX[dir]["#{plugin_slug.delete('-')}.json"] ||
              raise(ArgumentError, "Schema file not found for plugin `#{plugin_slug}` release `#{release.number}`")
          end
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
