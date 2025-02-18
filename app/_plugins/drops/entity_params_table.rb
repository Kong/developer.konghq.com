# frozen_string_literal: true

require 'yaml'

require_relative '../lib/site_accessor'

module Jekyll
  module Drops
    class EntityParamsTable < Liquid::Drop # rubocop:disable Style/Documentation
      class EntityParamsField < Liquid::Drop # rubocop:disable Style/Documentation
        def initialize(config, field) # rubocop:disable Lint/MissingSuper
          @config = config
          @field = field || {}
        end

        def name
          @name ||= @config.fetch('name')
        end

        def default_value
          @default_value ||= @field['default']
        end

        def array?
          @field['type'] == 'array'
        end

        def description
          @description ||= @config['description'] || @field['description']
        end
      end

      include Jekyll::SiteAccessor

      def initialize(config, release_number) # rubocop:disable Lint/MissingSuper
        @config = config
        @release_number = release_number
      end

      def fields
        @fields ||= params.sort_by(&:name)
      end

      def params
        @params ||= @config.fetch('config', []).map do |f|
          keys = f.fetch('name').split('.').map { |k| "properties.#{k}" }.join('.')
          EntityParamsField.new(f, schema.dig(*keys.split('.')))
        end
      end

      private

      def schema
        @schema ||= YAML.load(File.read(schema_file)).dig('components', 'schemas', @config.fetch('entity'))
      end

      def schema_file
        @schema_file ||= begin
          path = File.join('api-specs', 'gateway', 'admin-ee', @release_number, 'openapi.yaml')
          raise ArgumentError, "Schema file not found: #{path}." unless File.exist?(path)

          path
        end
      end
    end
  end
end
