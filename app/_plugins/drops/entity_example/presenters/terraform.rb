# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module Terraform
          class Base < Presenters::Base
            def data
              @data ||= Utils::VariableReplacer::TerraformData.run(
                data: @example_drop.data,
                variables: variables
              )
            end

            def target
              return nil if @example_drop.target.key == 'global'

              @example_drop.target.key
            end

            def product
              @product ||= @example_drop.product
            end

            def provider_source
              @provider_source ||= if @example_drop.product == 'gateway'
                                     'konnect'
                                   else
                                     'konnect-beta'
                                   end
            end

            def provider
              @provider ||= if @example_drop.product == 'gateway'
                              'konnect_gateway'
                            else
                              'konnect_event_gateway'
                            end
            end

            def resource_name
              "#{provider}_#{entity_type}"
            end

            def render
              tfData = data.clone
              tfData.delete("name")
              output(
                tfData,
                1,
                true,
                "\n"
              )
            end

            def output(object, depth, is_root, eol)
              object.map do |k, v|
                if v.is_a?(Hash)
                  output_hash(k, v, depth, is_root, eol)
                elsif v.is_a?(Array)
                  output_list(k, v, depth)
                else
                  line("#{k} = #{quote(v)}", depth, eol)
                end
              end.join
            end

            def output_hash(key, input, depth, is_root, eol)
              s = ''
              s += "\n" unless is_root
              s += line("#{key} = {", depth, eol)
              s += output(input, (depth + 1), false, eol)
              s += line('}', depth, eol)
              s
            end

            def output_hash_in_list(input, depth)
              s = "\n"
              s += line('{', (depth + 1))
              s += output(input, (depth + 2), false, "\n")
              s + line('}, ', (depth + 1))
            end

            def output_list(key, input, depth)
              s = line("#{key} = [", depth, '')
              input.each do |v|
                s += if v.is_a?(Hash)
                       output_hash_in_list(v, depth)
                     else
                       "#{line(quote(v), (depth + 1), '').strip}, "
                     end
              end

              s = s.rstrip.chomp(',')
              s + end_list(input, depth)
            end

            def end_list(input, depth)
              last_line = line(']', depth, "\n")
              return last_line if input.last.is_a?(Hash)

              last_line.lstrip
            end

            def line(input, depth, eol = "\n")
              "#{'  ' * depth}#{input}#{eol}"
            end

            def quote(input)
              return '' if input.nil?

              return input if input.is_a?(String) && input.start_with?("var.")

              return input if ['true', 'false', true, false].include?(input)

              return input if input.is_a?(Numeric)

              return "<<EOF\n#{input.rstrip}\nEOF" if input.include?("\n")

              "\"#{input.gsub('"', '\\"')}\""
            end

            def to_s
              <<~TERRAFORM
                #{render.strip}
              TERRAFORM
            end

            def template_file
              '/components/entity_example/format/terraform.md'
            end
          end

          class Plugin < Base
            def data
              @data ||= Utils::VariableReplacer::TerraformData.run(
                data: @example_drop.data.except(*targets.keys),
                variables: variables
              )
            end

            def variable_names
              keys = []
              variables.each do |k, v|
                keys = v['value'].gsub("$","").downcase
              end
              keys
            end
          end

          class EventGatewayPolicy < Base
            def entity_type
              "#{@example_drop.policy_target}_policy_#{@example_drop.data['type']}"
            end

            def data
              @data ||= Utils::VariableReplacer::TerraformData.run(
                data: @example_drop.data,
                variables: variables
              )
            end

            def variable_names
              keys = []
              variables.each do |k, v|
                keys = v['value'].gsub('$', '').downcase
              end
              keys
            end
          end
        end
      end
    end
  end
end
