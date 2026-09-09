# frozen_string_literal: true

module Jekyll
  module PolicyYaml
    # A predicate over (node_path, node, context), used to decide whether a
    # Transform applies to a given node while walking the YAML tree.
    class Condition
      def self.path(path)
        new { |node_path, _node, _context| node_path == path }
      end

      def self.root
        path([])
      end

      def self.kind(kind)
        new { |_path, node, _context| node['kind'] == kind }
      end

      def self.field(name)
        new { |_path, node, _context| node.key?(name) }
      end

      def self.kubernetes
        new { |_path, _node, context| context[:env] == :kubernetes }
      end

      def self.all(*conditions)
        new { |path, node, context| conditions.all? { |condition| condition.call(path, node, context) } }
      end

      def self.any(*conditions)
        new { |path, node, context| conditions.any? { |condition| condition.call(path, node, context) } }
      end

      def initialize(&predicate)
        @predicate = predicate
      end

      def call(path, node, context)
        @predicate.call(path, node, context)
      end
    end
  end
end
