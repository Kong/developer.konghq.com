# frozen_string_literal: true

require 'yaml'

module Jekyll
  module Drops
    class KonnectRolesTable < Liquid::Drop # rubocop:disable Style/Documentation
      def initialize(config) # rubocop:disable Lint/MissingSuper
        @config = config

        validate_config!
      end

      def roles
        @roles ||= schema.dig('properties', 'roles', 'properties').sort
      end

      def schema
        @schema ||= begin
          key = @config.fetch('schema')
          raise ArgumentError, "Couldn't find schema `#{key}`" unless schemas.key?(key)

          schemas.fetch(key)
        end
      end

      private

      def validate_config!
        raise ArgumentError, 'Missing  `schema` in konnect_roles_table' unless @config.key?('schema')
      end

      def schemas
        @schemas ||= YAML
                     .load(File.read(api_spec_file))
                     .dig('components', 'responses', 'Roles', 'content', 'application/json', 'schema', 'properties')
      end

      def api_spec_file
        # XXX: roles not defined in the spec
        #   Networks
        #   Service Catalog
        #   Portals
        #   Application Auth Strategies
        #   DCR
        # XXX: teams aren't defined in the spec
        @api_spec_file ||= begin
          folder = Dir.glob('api-specs/konnect/identity/*').max_by { |f| f[/\d+/].to_i }
          File.join(folder, 'openapi.yaml')
        end
      end
    end
  end
end
