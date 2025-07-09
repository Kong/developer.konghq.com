# frozen_string_literal: true

require 'yaml'

module Jekyll
  module Utils
    class HashToYAML
      def initialize(hash)
        @hash = hash
      end

      def convert(indent_level: 2)
        indent_yaml(YAML.dump(@hash).delete_prefix("---\n").chomp, indent_level)
      end

      def indent_yaml(yaml_string, indent_level)
        indented_yaml = []
        yaml_string.lines.each do |line|
          indented_yaml << if line.match?(/^(\s*)-\s+/)
                             ' ' * indent_level + line
                           else
                             line.gsub(/^(\s+)/) { |spaces| ' ' * (spaces.length + indent_level) }
                           end
        end
        indented_yaml.join
      end
    end
  end
end
