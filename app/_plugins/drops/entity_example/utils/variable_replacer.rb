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
                # First handle literal blocks (which need line-level replacement)
                data = handle_literal_blocks(data)

                data.gsub(regex) do |match|
                  variable = Regexp.last_match(1)
                  # Skip literal blocks - they're already handled
                  next match if variables.dig(variable, 'literal_block')

                  replace_variable(data, variable) || match
                end
              else
                data
              end
            end

            def handle_literal_blocks(data)
              data
            end

            def replace_variable(_data, variable)
              variables.dig(variable, 'value')
            end
          end

          class DeckData < Data
            def handle_literal_blocks(data)
              literal_vars = variables.select { |_, v| v && v['literal_block'] }.keys
              return data if literal_vars.empty?

              literal_pattern = literal_vars.map { |key| Regexp.escape("${#{key}}") }.join('|')

              # Match entire line: key: value_with_variable
              line_regex = /^( *)(\S+):\s*(["']?)(?:#{literal_pattern})\3\s*$/

              data.gsub(line_regex) do
                indentation = Regexp.last_match(1)
                key = Regexp.last_match(2)

                # Extract variable name from the matched line
                variable = variables.keys.find { |var| Regexp.last_match(0).include?("${#{var}}") }

                if variable
                  env_variable = variables.dig(variable, 'value').gsub('$', 'DECK_')
                  value_indentation = indentation.length + 2
                  "#{indentation}#{key}: |-\n#{' ' * value_indentation}${{ env \"#{env_variable}\" }}"
                else
                  Regexp.last_match(0)
                end
              end
            end

            def replace_variable(_data, variable)
              value = variables.dig(variable, 'value')
              return nil unless value

              env_variable = value.gsub('$', 'DECK_')
              "${{ env \"#{env_variable}\" }}"
            end
          end

          class TerraformData < Data
            def replace_variable(_data, variable)
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
