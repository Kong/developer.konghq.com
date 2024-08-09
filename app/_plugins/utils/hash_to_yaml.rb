# frozen_string_literal: true

require 'yaml'

module Jekyll
  module Utils
    class HashToYAML
      def initialize(hash)
        @hash = hash
      end

      def convert
        indent_yaml(YAML.dump(@hash).delete_prefix("---\n"))
      end

      def indent_yaml(yaml_string, indent_level = 2)
        indented_yaml = []
        yaml_string.lines.each do |line|
          if line.match?(/^(\s*)-\s+/)
            indented_yaml << ' ' * indent_level + line
          else
            indented_yaml << line.gsub(/^(\s+)/) { |spaces| ' ' * (spaces.length + indent_level) }
          end
        end
        indented_yaml.join
      end
    end
  end
end
