# frozen_string_literal: true

module Jekyll
  module PolicyYaml
    # Renders a processed Universal-style YAML document as a Terraform `resource` block.
    class TerraformRenderer
      RESOURCE_PREFIX = "  provider = konnect-beta\n"
      RESOURCE_SUFFIX = <<-HCL
  labels   = {
  "kuma.io/mesh" = konnect_mesh.my_mesh.name
  }
  cp_id    = konnect_mesh_control_plane.my_meshcontrolplane.id
  mesh     = konnect_mesh.my_mesh.name
      HCL

      def initialize(yaml_data)
        @yaml_data = yaml_data
      end

      def render
        "resource \"#{resource_type}\" \"#{resource_label}\" {\n" \
          "#{RESOURCE_PREFIX}#{body}#{RESOURCE_SUFFIX}}\n"
      end

      private

      def resource_type
        "konnect_#{snake_case(@yaml_data['type'])}"
      end

      def resource_label
        @yaml_data['name'].gsub('-', '_')
      end

      def body
        @yaml_data.each_with_object(+'') do |(key, value), result|
          next if key == 'mesh' # We use a reference at the end of the provider

          result << convert(key, value, 1)
        end
      end

      def snake_case(str)
        str.gsub(/([a-z])([A-Z])/, '\1_\2').gsub(/([A-Z])([A-Z][a-z])/, '\1_\2').downcase
      end

      def convert(key, value, indent_level, in_array: false, last: true)
        case value
        when Hash then convert_hash(key, value, indent_level, in_array, last)
        when Array then convert_array(key, value, indent_level, in_array, last)
        else convert_scalar(key, value, indent_level, in_array, last)
        end
      end

      def convert_hash(key, value, indent_level, in_array, last)
        indent = '  ' * indent_level
        opening = in_array ? "#{indent}{\n" : "#{indent}#{snake_key(key)} = {\n"
        entries = value.each_with_index.reduce(+'') do |acc, ((k, v), index)|
          acc << convert(k, v, indent_level + 1, last: index == value.size - 1)
        end
        "#{opening}#{entries}#{indent}}#{trailing_comma(in_array, last)}\n"
      end

      def convert_array(key, value, indent_level, in_array, last)
        indent = '  ' * indent_level
        entries = value.each_with_index.reduce(+'') do |acc, (v, index)|
          acc << convert('', v, indent_level + 1, in_array: true, last: index == value.size - 1)
        end
        "#{indent}#{snake_key(key)} = [\n#{entries}#{indent}]#{trailing_comma(in_array, last)}\n"
      end

      def convert_scalar(key, value, indent_level, in_array, last)
        indent = '  ' * indent_level
        "#{indent}#{snake_key(key)} = \"#{value}\"#{trailing_comma(in_array, last)}\n"
      end

      def snake_key(key)
        key.empty? ? key : snake_case(key)
      end

      def trailing_comma(in_array, last)
        in_array && !last ? ',' : ''
      end
    end
  end
end
