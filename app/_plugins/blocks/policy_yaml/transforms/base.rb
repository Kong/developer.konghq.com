# frozen_string_literal: true

module Jekyll
  module PolicyYaml
    module Transforms
      # A rewrite rule applied to a single YAML node while walking the tree:
      # `applies?` decides whether the node matches, `call` returns its replacement.
      class Base
        attr_reader :condition

        def initialize(condition)
          @condition = condition
        end

        def applies?(path, node, context)
          condition.call(path, node, context)
        end

        def call(_node, _context)
          raise NotImplementedError
        end
      end
    end
  end
end
