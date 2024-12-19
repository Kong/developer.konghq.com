# frozen_string_literal: true

require 'json'
require_relative '../../lib/site_accessor'

module Jekyll
  module PluginPages
    class Schema
      include Jekyll::SiteAccessor

      def self.all(plugin:)
        plugin.releases.map do |release|
          new(release:, plugin_slug: plugin.slug)
        end
      end

      attr_reader :release

      def initialize(release:, plugin_slug:)
        @release = release
        @plugin_slug = plugin_slug
      end

      def to_json(*_args)
        schema
      end

      def compatible_protocols
        @compatible_protocols ||= schema.dig('properties', 'protocols', 'items', 'enum')
      end

      private

      def schema
        @schema ||= JSON.parse(File.read(file_path))
      end

      def file_path
        @file_path ||= File.join(
          site.config['plugin_schemas_path'],
          @plugin_slug,
          "#{@release.number}.json"
        )
      end
    end
  end
end
