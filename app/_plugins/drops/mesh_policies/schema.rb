# frozen_string_literal: true

require 'json'
require 'yaml'
require_relative '../../lib/site_accessor'

module Jekyll
  module Drops
    module MeshPolicies
      class Schema < Liquid::Drop # rubocop:disable Style/Documentation
        include Jekyll::SiteAccessor

        def self.all(policy:)
          policy.releases.map do |release|
            new(release:, policy:)
          end
        end

        attr_reader :release

        def initialize(release:, policy:) # rubocop:disable Lint/MissingSuper
          @release = release
          @policy = policy
        end

        def as_json
          schema
        end

        private

        def schema # rubocop:disable Metrics/AbcSize
          @schema ||= case @policy.type
                      when 'proto'
                        JSON.parse(File.read(file_path))
                      when 'crd'
                        yaml = YAML.load(File.read(file_path))
                        yaml['spec']['versions'][0]['schema']['openAPIV3Schema']
                      when 'policy'
                        yaml = YAML.load(File.read(file_path))
                        yaml['spec']['versions'][0]['schema']['openAPIV3Schema']['properties']['spec']
                      end
        end

        def file_path # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          @file_path ||= begin
            release = @release.label ? @release.to_s : "#{@release.number}.x"
            case @policy.type
            when 'proto'
              File.join(site.config['mesh_policy_schemas_path'], release, 'raw', 'protos',
                        "#{@policy.name}.json")
            when 'crd'
              File.join(site.config['mesh_policy_schemas_path'], release, 'raw', 'crds',
                        "#{@policy.name}.yaml")
            when 'policy'
              File.join(site.config['mesh_policy_schemas_path'], release, 'raw', 'crds',
                        "kuma.io_#{@policy.name.downcase}.yaml")
            else
              raise ArgumentError,
                    "Invalid mesh_policy type: `#{@policy.type}` for policy `#{@policy.slug}`."
            end
          end
        end
      end
    end
  end
end
