# frozen_string_literal: true

require_relative './base'

module Jekyll
  module PolicyYaml
    module Transforms
      # Rewrites a MeshService `backendRef` (under a route's `backendRefs` or
      # `requestMirror.backendRef`) into its Kubernetes/Universal, legacy/current shape.
      class BackendRefTransform < Base
        def initialize
          super(Condition.any(
            Condition.all(Condition.path(%w[spec to rules default backendRefs]), Condition.kind('MeshService')),
            Condition.all(Condition.path(%w[spec to rules default filters requestMirror backendRef]),
                          Condition.kind('MeshService'))
          ))
        end

        def call(backend_ref, context)
          if context[:legacy_output]
            legacy_ref(backend_ref, context[:env])
          else
            ref(backend_ref, context[:env])
          end
        end

        private

        def legacy_ref(backend_ref, env)
          hash = { 'kind' => 'MeshService', 'name' => legacy_name(backend_ref, env) }
          hash['kind'] = 'MeshServiceSubset' if backend_ref.key?('_version')
          apply_weight(hash, backend_ref)
          hash['tags'] = { 'version' => backend_ref['_version'] } if backend_ref.key?('_version')
          hash
        end

        def legacy_name(backend_ref, env)
          return backend_ref['name'] if env == :universal

          [backend_ref['name'], backend_ref['namespace'], 'svc', backend_ref['port']].compact.join('_')
        end

        def ref(backend_ref, env)
          hash = { 'kind' => 'MeshService', 'name' => backend_ref['name'] }
          hash['namespace'] = backend_ref['namespace'] if env == :kubernetes
          hash['port'] = backend_ref['port']
          apply_weight(hash, backend_ref)
          hash['name'] = "#{backend_ref['name']}-#{backend_ref['_version']}" if backend_ref.key?('_version')
          hash
        end

        def apply_weight(hash, backend_ref)
          hash['weight'] = backend_ref['weight'] if backend_ref.key?('weight')
        end
      end
    end
  end
end
