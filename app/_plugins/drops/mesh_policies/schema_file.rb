# frozen_string_literal: true

require 'json'
require 'yaml'
require_relative '../../lib/site_accessor'

module Jekyll
  module Drops
    module MeshPolicies
      class SchemaFile < Liquid::Drop # rubocop:disable Style/Documentation
        include Jekyll::SiteAccessor

        attr_reader :release

        def initialize(release:, type:, name:) # rubocop:disable Lint/MissingSuper
          @release = release
          @type = type
          @name = name
        end

        def as_json
          schema
        end

        private

        def schema # rubocop:disable Metrics/AbcSize
          @schema ||= case @type
                      when 'proto'
                        JSON.parse(File.read(file_path))['definitions'][@name]
                      when 'crd'
                        yaml = YAML.load(File.read(file_path))
                        yaml['spec']['versions'][0]['schema']['openAPIV3Schema']
                      when 'policy'
                        yaml = YAML.load(File.read(file_path))
                        yaml['spec']['versions'][0]['schema']['openAPIV3Schema']['properties']['spec']
                      end
        end

        def file_path # rubocop:disable Metrics/MethodLength
          @file_path ||= case @type
                         when 'proto'
                           find_file_path(File.join('raw', 'protos', "#{@name}.json"))
                         when 'crd'
                           find_file_path(File.join('raw', 'crds', "#{@name}.yaml"))
                         when 'policy'
                           find_file_path(File.join('raw', 'crds', "kuma.io_#{@name.downcase}.yaml"))
                         else
                           raise ArgumentError,
                                 "Invalid mesh_policy type: `#{@type}` for policy `#{@name}`."
                         end
        end

        def find_file_path(path)
          roots
            .map { |root| File.join(root, path) }
            .find { |full_path| File.exist?(full_path) }
        end

        def roots
          [
            File.join('app/assets/mesh', @release.label ? @release.to_s : @release.number.to_s),
            File.join('app/assets/mesh', "#{@release.number}.x"),
            File.join(site.config['mesh_policy_schemas_path'], @release.label ? @release.to_s : "#{@release.number}.x")
          ]
        end
      end
    end
  end
end
