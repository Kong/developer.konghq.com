# frozen_string_literal: true

module Jekyll
  module PolicyYaml
    # Walks a parsed YAML document, applying every matching Transform to each
    # Hash node it visits (depth-first, root to leaves).
    class NodeProcessor
      def initialize(transforms)
        @transforms = transforms
      end

      def process(node, context, path = [])
        case node
        when Hash then process_hash(node, context, path)
        when Array then node.map { |item| process(item, context, path) }
        else node
        end
      end

      private

      def process_hash(node, context, path)
        node = apply_transforms(node, context, path)
        node.transform_values.with_index { |value, index| process(value, context, path + [node.keys[index]]) }
      end

      def apply_transforms(node, context, path)
        @transforms.reduce(node) do |current, transform|
          transform.applies?(path, current, context) ? transform.call(current, context) : current
        end
      end
    end
  end
end
