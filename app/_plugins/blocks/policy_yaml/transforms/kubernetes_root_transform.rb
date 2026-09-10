# frozen_string_literal: true

require_relative './base'

module Jekyll
  module PolicyYaml
    module Transforms
      # Wraps the root policy node into the Kubernetes apiVersion/kind/metadata/spec shape.
      class KubernetesRootTransform < Base
        def initialize(api_version)
          super(Condition.all(Condition.root, Condition.kubernetes))
          @api_version = api_version
        end

        def call(node, context)
          {
            'apiVersion' => @api_version,
            'kind' => node['type'],
            'metadata' => metadata(node, context),
            'spec' => node['spec']
          }
        end

        private

        def metadata(node, context)
          {
            'name' => node['name'],
            'namespace' => context[:namespace],
            **labels(node)
          }
        end

        def labels(node)
          return {} unless node['labels'] || node['mesh']

          {
            'labels' => {
              **(node['labels'] || {}),
              **(node['mesh'] ? { 'kuma.io/mesh' => node['mesh'] } : {})
            }
          }
        end
      end
    end
  end
end
