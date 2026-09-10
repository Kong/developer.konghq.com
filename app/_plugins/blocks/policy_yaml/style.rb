# frozen_string_literal: true

module Jekyll
  module PolicyYaml
    # One of the four renderings produced for a policy (Kubernetes/Universal,
    # each with a legacy tag-based variant and a current MeshService-ref variant).
    Style = Struct.new(:name, :env, :legacy_output, :namespace, keyword_init: true) do
      def context
        { env: env, legacy_output: legacy_output, namespace: namespace }
      end
    end
  end
end
