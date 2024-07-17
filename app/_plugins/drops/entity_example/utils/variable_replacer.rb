# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      module Utils
        module VariableReplacer
          class URL
            def self.run(string:, variables:)
              variables.each_with_object(string.dup) do |(key, value), result|
                placeholder = "{#{key}}"
                result.gsub!(placeholder, value) if result.include?(placeholder)
              end
            end
          end

          class Text
            def self.run(string:, variables:)
              variables.each_with_object(string.dup) do |(key, value), result|
                result.gsub!(key, value) if result.include?(key)
              end
            end
          end
        end
      end
    end
  end
end
