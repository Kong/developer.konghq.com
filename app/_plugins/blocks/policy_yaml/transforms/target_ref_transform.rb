# frozen_string_literal: true

require_relative './base'

module Jekyll
  module PolicyYaml
    module Transforms
      # Rewrites a MeshService `targetRef` under `spec.to.targetRef` into its
      # Kubernetes or Universal shape, legacy tag-based or MeshService-ref based.
      class TargetRefTransform < Base
        def initialize
          super(Condition.all(Condition.path(%w[spec to targetRef]), Condition.kind('MeshService')))
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

          {
            'kind' => 'MeshService',
            'name' => target_ref['name'],
            'namespace' => target_ref['namespace'],
            'sectionName' => target_ref['sectionName']
          }
        end

        def legacy_kubernetes_ref(target_ref)
          {
            'kind' => 'MeshService',
            'name' => [target_ref['name'], target_ref['namespace'], 'svc', target_ref['_port']].compact.join('_')
          }
        end

        def universal_ref(target_ref, legacy)
          return { 'kind' => 'MeshService', 'name' => target_ref['name'] } if legacy

          { 'kind' => 'MeshService', 'name' => target_ref['name'], 'sectionName' => target_ref['sectionName'] }
        end
      end
    end
  end
end
