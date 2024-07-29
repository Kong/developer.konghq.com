# frozen_string_literal: true

module Jekyll
  module Blocks
    class Attributes
      def self.parse(string)
        attributes = {}
        string.scan(/(\w+)=(?:"([^"]+)"|\{\{\s*([^}]+)\s*\}\})/) do |key, value1, value2|
          attributes[key] = value1 || "{{#{value2}}}"
        end
        attributes
      end

      def self.evaluate(attr, context)
        Liquid::Template.parse(attr).render(context)
      end
    end
  end
end
