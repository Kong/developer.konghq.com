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

          class Data
            def self.run(data:, variables:)
              new(variables:).run(data)
            end

            attr_reader :variables

            def initialize(variables:)
              @variables = variables
            end

            def run(data) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
              keys_pattern = variables.keys.map { |key| Regexp.escape(key.to_s) }.join('|')
              regex = /\$\{(#{keys_pattern})\}/

              case data
              when Hash
                data.transform_values { |value| run(value) }
              when Array
                data.map { |item| run(item) }
              when String
                data.gsub(regex) do |match|
                  replace_variable(Regexp.last_match(1)) || match
                end
              else
                data
              end
            end

            def replace_variable(variable)
              variables.dig(variable, 'value')
            end
          end

          class DeckData < Data
            def replace_variable(variable)
              value = super

              return nil unless value

              env_variable = value.gsub('$', 'DECK_')
              "${{ env \"#{env_variable}\" }}"
            end
          end

          class TerraformData < Data
            def replace_variable(variable)
              value = super

              return nil unless value

              env_variable = value.gsub('$', '').downcase
              "var.#{env_variable}"
            end
          end

        end
      end
    end
  end
end
