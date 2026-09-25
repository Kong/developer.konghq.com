# frozen_string_literal: true

require 'json'

module Jekyll
  module PolicyYaml
    # Renders a processed Universal-style YAML document as a Terraform `resource` block.
    class TerraformRenderer
      RESOURCE_PREFIX = "  provider = konnect-beta\n"
      HCL_IDENTIFIER = /\A[A-Za-z_][A-Za-z0-9_-]*\z/
      # Field names the pinned provider models as int-or-string wrapper
      # objects: every provider instance of a bare name here has the wrapper
      # shape. `client`, `overall`, and `random` match only under `sampling`.
      WRAPPER_FIELD_NAMES = %w[
        percentage
        standard_deviation_factor
        active_request_bias
        healthy_panic_threshold
        target_port
      ].freeze
      SAMPLING_FIELD_NAMES = %w[client overall random].freeze
      # Resource types the Konnect API serves at control-plane scope
      # (/api/<plural> without a mesh segment): the pinned provider's
      # resources for them take no `mesh` argument, so the rendered block
      # must set neither a `mesh` attribute nor a `kuma.io/mesh` label.
      CP_SCOPED_TYPES = %w[HostnameGenerator].freeze
      # The HCL key of the mesh label the suffix adds; a source label with
      # the same key is dropped, so the block never defines the label twice.
      MESH_LABEL_KEY = '"kuma.io/mesh"'

      def initialize(yaml_data)
        @yaml_data = yaml_data
      end

      def render
        "resource \"#{resource_type}\" \"#{resource_label}\" {\n" \
          "#{RESOURCE_PREFIX}#{body}#{suffix}}\n"
      end

      private

      def resource_type
        "konnect_mesh_#{snake_case(@yaml_data['type'].sub(/\AMesh/, ''))}"
      end

      def resource_label
        @yaml_data['name'].gsub('-', '_')
      end

      def body
        @yaml_data.each_with_object(+'') do |(key, value), result|
          next if key == 'mesh' # We use a reference at the end of the provider
          next if key == 'labels' # Rendered once, merged, in the suffix
          # `status` is system-managed: every konnect_mesh_* resource models
          # it read-only, so a resource block that sets it never validates.
          next if key == 'status'

          result << convert(key, value, 1)
        end
      end

      # One `labels` attribute per resource: the source labels first, then
      # the mesh label for mesh-scoped resources. Control-plane-scoped
      # resources without source labels render no `labels` attribute at all.
      def suffix
        "#{labels_block}  cp_id    = konnect_mesh_control_plane.my_meshcontrolplane.id\n#{mesh_line}"
      end

      def labels_block
        return +'' if @yaml_data['labels'].nil? && cp_scoped?

        entries = (@yaml_data['labels'] || {})
                  .reject { |key, _value| hcl_key(key) == MESH_LABEL_KEY }
                  .map do |key, value|
          "  #{hcl_key(key)} = #{format_value(
            value, '  '
          )}"
        end
        entries << "  #{MESH_LABEL_KEY} = konnect_mesh.my_mesh.name" unless cp_scoped?
        "  labels   = {\n#{entries.join("\n")}\n  }\n"
      end

      def mesh_line
        return +'' if cp_scoped?

        "  mesh     = konnect_mesh.my_mesh.name\n"
      end

      def cp_scoped?
        CP_SCOPED_TYPES.include?(@yaml_data['type'])
      end

      def snake_case(str)
        str.gsub(/([a-z])([A-Z])/, '\1_\2').gsub(/([A-Z])([A-Z][a-z])/, '\1_\2').downcase
      end

      def convert(key, value, indent_level, in_array: false, last: true, parent_key: nil, array_key: nil)
        case value
        when Hash then convert_hash(key, value, indent_level, in_array, last, parent_key, array_key)
        when Array then convert_array(key, value, indent_level, in_array, last, array_key)
        else convert_scalar(key, value, indent_level, in_array, last, parent_key, array_key)
        end
      end

      def convert_hash(key, value, indent_level, in_array, last, _parent_key, array_key)
        indent = '  ' * indent_level
        opening = in_array ? "#{indent}{\n" : "#{indent}#{hcl_key(key)} = {\n"
        entries = value.each_with_index.reduce(+'') do |acc, ((k, v), index)|
          acc << convert(k, v, indent_level + 1, last: index == value.size - 1, parent_key: key, array_key: array_key)
        end
        "#{opening}#{entries}#{indent}}#{trailing_comma(in_array, last)}\n"
      end

      def convert_array(key, value, indent_level, in_array, last, _array_key)
        indent = '  ' * indent_level
        entries = value.each_with_index.reduce(+'') do |acc, (v, index)|
          acc << convert('', v, indent_level + 1, in_array: true, last: index == value.size - 1,
                                                  parent_key: '', array_key: key)
        end
        "#{indent}#{hcl_key(key)} = [\n#{entries}#{indent}]#{trailing_comma(in_array, last)}\n"
      end

      def convert_scalar(key, value, indent_level, in_array, last, parent_key, array_key)
        indent = '  ' * indent_level
        prefix = in_array ? '' : "#{hcl_key(key)} = "
        rendered = scalar_rendering(key, value, indent, parent_key, array_key)
        return "#{indent}#{prefix}#{rendered}#{trailing_comma(in_array, last)}\n" unless heredoc?(rendered, in_array)

        "#{indent}#{prefix}#{rendered}#{trailing_comma(in_array, last).sub(',', "\n#{indent},")}\n"
      end

      def scalar_rendering(key, value, indent, parent_key, array_key)
        # The provider types jsonPatches[].value as a string holding RFC 7159
        # JSON text, so a scalar patch value renders as its JSON encoding.
        return json_patch_value(value) if key == 'value' && array_key == 'jsonPatches'

        wrapper = wrapper_object(key, value, parent_key)
        return wrapper unless wrapper.nil?

        format_value(value, indent)
      end

      def json_patch_value(value)
        format_scalar(JSON.generate(value))
      end

      # Renders a field the provider models as an int-or-string wrapper as a
      # wrapper object: Integer/Float as an `integer` attribute, String as a
      # `str` attribute. Other value classes keep their plain rendering.
      def wrapper_object(key, value, parent_key)
        return nil unless wrapper_field?(key, parent_key)

        case value
        when Integer, Float then "{ integer = #{value} }"
        when String then "{ str = #{format_scalar(value)} }"
        end
      end

      def wrapper_field?(key, parent_key)
        snake_key = snake_case(key)
        return true if WRAPPER_FIELD_NAMES.include?(snake_key)

        SAMPLING_FIELD_NAMES.include?(snake_key) && snake_case(parent_key.to_s) == 'sampling'
      end

      def heredoc?(rendered, in_array)
        in_array && rendered.include?('<<-EOT')
      end

      def format_value(value, indent)
        if value.is_a?(String) && value.include?("\n")
          heredoc_value(value, indent)
        else
          format_scalar(value)
        end
      end

      def heredoc_value(value, indent)
        body = value.end_with?("\n") ? value : "#{value}\n"
        "<<-EOT\n#{body.gsub('${', '$${')}#{indent}EOT"
      end

      def hcl_key(key)
        snake_key = snake_case(key)
        snake_key.match?(HCL_IDENTIFIER) ? snake_key : "\"#{snake_key}\""
      end

      def format_scalar(value)
        case value
        when Integer, Float, TrueClass, FalseClass then value.to_s
        else "\"#{escape_hcl_string(value)}\""
        end
      end

      # Escapes a string so it parses as a single HCL string literal: backslash
      # and double quote are escaped, and a literal template interpolation
      # start is doubled so terraform reads it as the literal sequence.
      def escape_hcl_string(value)
        value
          .gsub('\\') { '\\\\' }
          .gsub('"') { '\\"' }
          .gsub('${', '$${')
      end

      def trailing_comma(in_array, last)
        in_array && !last ? ',' : ''
      end
    end
  end
end
