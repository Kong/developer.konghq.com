# frozen_string_literal: true

require_relative './base'

module Jekyll
  module PolicyYaml
    module Transforms
      # Rewrites a MeshService or MeshMultiZoneService `targetRef` under
      # `spec.to.targetRef` into its Kubernetes or Universal shape, legacy
      # tag-based or MeshService-ref based. Only applies to name-based refs:
      # a labels-based ref is already in its final shape in every style.
      class TargetRefTransform < Base
        def initialize
          super(Condition.all(
            Condition.path(%w[spec to targetRef]),
            Condition.any(Condition.kind('MeshService'), Condition.kind('MeshMultiZoneService')),
            Condition.field('name')
          ))
        end

        def call(target_ref, context)
          if context[:env] == :kubernetes
            kubernetes_ref(target_ref, context[:legacy_output])
          else
            universal_ref(target_ref, context[:legacy_output])
          end
        end

        private

        def kubernetes_ref(target_ref, legacy)
          return legacy_kubernetes_ref(target_ref) if legacy

          ref = { 'kind' => target_ref['kind'], 'name' => target_ref['name'] }
          ref['namespace'] = target_ref['namespace'] if target_ref['namespace']
          ref['sectionName'] = target_ref['sectionName'] if target_ref['sectionName']
          ref
        end

        def legacy_kubernetes_ref(target_ref)
          {
            'kind' => 'MeshService',
            'name' => [target_ref['name'], target_ref['namespace'], 'svc', target_ref['_port']].compact.join('_')
          }
        end

        def universal_ref(target_ref, legacy)
          return { 'kind' => 'MeshService', 'name' => target_ref['name'] } if legacy

          ref = { 'kind' => target_ref['kind'], 'name' => target_ref['name'] }
          ref['sectionName'] = target_ref['sectionName'] if target_ref['sectionName']
          ref
        end
      end
    end
  end
end
