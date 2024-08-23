# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module Terraform
          class Base < Liquid::Drop
            def initialize(example_drop:)
              @example_drop = example_drop
            end

            def data
              @data ||= @example_drop.data
            end

            def target
              return nil if @example_drop.target.key == "global"
              @example_drop.target.key
            end

            def entity_type
              @entity_type ||= @example_drop.entity_type
            end

            def provider
              "konnect_gateway"
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
          end

          class Plugin < Base
          end
        end
      end
    end
  end
end
