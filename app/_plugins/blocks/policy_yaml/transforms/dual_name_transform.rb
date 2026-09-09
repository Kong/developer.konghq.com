# frozen_string_literal: true

require_relative './base'

module Jekyll
  module PolicyYaml
    module Transforms
      # Collapses a node with separate `name_uni`/`name_kube` fields into a
      # single `name`, picking the one that matches the current environment.
      class DualNameTransform < Base
        def initialize
          super(Condition.any(Condition.field('name_uni'), Condition.field('name_kube')))
        end

        def call(node, context)
          node_copy = DeepCopy.call(node)
          node_copy.delete('name_uni')
          node_copy.delete('name_kube')
          node_copy['name'] = context[:env] == :kubernetes ? node['name_kube'] : node['name_uni']
          node_copy
        end
      end
    end
  end
end
