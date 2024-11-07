# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      module Utils
        module VariableReplacer
          class URL
            def self.run(url:, defaults:, variables:)
              url = url.dup
              url.scan(/\{(.*?)\}/).flatten.each do |p|
                value = variables[p] || "{#{defaults[p]['placeholder']}}"
                url.gsub!("{#{p}}", value)
              end

              url
            end
          end
        end
      end
    end
  end
end
