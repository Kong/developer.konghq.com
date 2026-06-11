# frozen_string_literal: true

module Jekyll
  module Utils
    class JsonSchemaDeref
      INTERNAL_REF = /\A#\/\$defs\/(?<name>[^\/]+)\z/

      def initialize(schema)
        @schema = schema || {}
        @defs = @schema.fetch('$defs', {})
      end

      def resolve
        resolve_node(@schema.except('$defs'), Set.new)
      end

      private

      def resolve_node(node, in_progress)
        case node
        when Hash  then resolve_hash(node, in_progress)
        when Array then node.map { |v| resolve_node(v, in_progress) }
        else            node
        end
      end

      def resolve_hash(hash, in_progress)
        ref = hash['$ref']
        return hash.transform_values { |v| resolve_node(v, in_progress) } unless ref

        m = INTERNAL_REF.match(ref)
        return inline_ref(m[:name], ref, in_progress) if m

        hash
      end

      def inline_ref(name, ref, in_progress)
        # Cycle guard: if already resolving this def, leave the $ref as-is
        return { '$ref' => ref } if in_progress.include?(name)

        subtree = @defs[name]
        return { '$ref' => ref } unless subtree

        resolve_node(subtree, in_progress | Set[name])
      end
    end
  end
end
