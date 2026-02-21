# frozen_string_literal: true

# Extracted from: https://github.com/kumahq/kuma-website/blob/master/jekyll-kuma-plugins/lib/jekyll/kuma-plugins/liquid/tags/policyyaml.rb

module Jekyll
  class RenderPolicyYaml < Liquid::Block
    TARGET_VERSION = Gem::Version.new('2.9')
    TF_TARGET_VERSION = Gem::Version.new('2.10')

    def has_path(path)
      ->(node_path, _, _) { node_path == path }
    end

    def root_path
      has_path([])
    end

    def kind_is(kind)
      ->(_, node, _) { node['kind'] == kind }
    end

    def _and(*conditions)
      ->(node_path, node, context) { conditions.all? { |cond| cond.call(node_path, node, context) } }
    end

    def _or(*conditions)
      ->(node_path, node, context) { conditions.any? { |cond| cond.call(node_path, node, context) } }
    end

    def has_field(field_name)
      ->(_, node, _) { node.key?(field_name) }
    end

    def is_kubernetes
      ->(_, _, context) { context[:env] == :kubernetes }
    end

    def initialize(tag_name, markup, options)
      super

      @params = { 'raw' => false, 'apiVersion' => 'kuma.io/v1alpha1', 'use_meshservice' => false }
      markup.strip.split(' ').each do |item|
        sp = item.split('=')
        @params[sp[0]] = sp[1] unless sp[1] == ''
      end

      @callbacks = []

      register_callback(
        _and(has_path(%w[spec to targetRef]), kind_is('MeshService')),
        lambda do |target_ref, context|
          case context[:env]
          when :kubernetes
            if context[:legacy_output]
              {
                'kind' => 'MeshService',
                'name' => [target_ref['name'], target_ref['namespace'], 'svc', target_ref['_port']].compact.join('_')
              }
            else
              {
                'kind' => 'MeshService',
                'name' => target_ref['name'],
                'namespace' => target_ref['namespace'],
                'sectionName' => target_ref['sectionName']
              }
            end
          when :universal
            if context[:legacy_output]
              {
                'kind' => 'MeshService',
                'name' => target_ref['name']
              }
            else
              {
                'kind' => 'MeshService',
                'name' => target_ref['name'],
                'sectionName' => target_ref['sectionName']
              }
            end
          end
        end
      )

      register_callback(
        _or(_and(has_path(%w[spec to rules default backendRefs]), kind_is('MeshService')),
            _and(has_path(%w[spec to rules default filters requestMirror backendRef]), kind_is('MeshService'))),
        lambda do |backend_ref, context|
          case context[:env]
          when :kubernetes
            if context[:legacy_output]
              {
                'kind' => 'MeshService',
                'name' => [backend_ref['name'], backend_ref['namespace'], 'svc', backend_ref['port']].compact.join('_')
              }.tap do |hash|
                hash['kind'] = 'MeshServiceSubset' if backend_ref.key?('_version')
                hash['weight'] = backend_ref['weight'] if backend_ref.key?('weight')
                if backend_ref.key?('_version')
                  hash['tags'] = {
                    'version' => backend_ref['_version']
                  }
                end
              end
            else
              {
                'kind' => 'MeshService',
                'name' => backend_ref['name'],
                'namespace' => backend_ref['namespace'],
                'port' => backend_ref['port']
              }.tap do |hash|
                hash['weight'] = backend_ref['weight'] if backend_ref.key?('weight')
                hash['name'] = backend_ref['name'] + '-' + backend_ref['_version'] if backend_ref.key?('_version')
              end
            end
          when :universal
            if context[:legacy_output]
              {
                'kind' => 'MeshService',
                'name' => backend_ref['name']
              }.tap do |hash|
                hash['kind'] = 'MeshServiceSubset' if backend_ref.key?('_version')
                hash['weight'] = backend_ref['weight'] if backend_ref.key?('weight')
                if backend_ref.key?('_version')
                  hash['tags'] = {
                    'version' => backend_ref['_version']
                  }
                end
              end
            else
              {
                'kind' => 'MeshService',
                'name' => backend_ref['name'],
                'port' => backend_ref['port']
              }.tap do |hash|
                hash['weight'] = backend_ref['weight'] if backend_ref.key?('weight')
                hash['name'] = backend_ref['name'] + '-' + backend_ref['_version'] if backend_ref.key?('_version')
              end
            end
          end
        end
      )

      register_callback(
        _or(has_field('name_uni'), has_field('name_kube')),
        lambda do |node, context|
          node_copy = deep_copy(node)
          node_copy.delete('name_uni')
          node_copy.delete('name_kube')

          case context[:env]
          when :kubernetes
            node_copy['name'] = node['name_kube']
          when :universal
            node_copy['name'] = node['name_uni']
          end

          node_copy
        end
      )

      register_callback(
        _and(root_path, is_kubernetes),
        lambda do |node, context|
          {
            'apiVersion' => @params['apiVersion'],
            'kind' => node['type'],
            'metadata' => {
              'name' => node['name'],
              'namespace' => context[:namespace],
              **(if node['labels'] || node['mesh']
                   { 'labels' => {
                                 **(node['labels'] || {}),
                                 **(node['mesh'] ? { 'kuma.io/mesh' => node['mesh'] } : {})
                   } }
                 else
                   {}
                 end)
            },
            'spec' => node['spec']
          }
        end
      )
    end

    # Register a callback to be executed when a node matches a condition
    def register_callback(condition, callback)
      @callbacks << [condition, callback]
    end

    def deep_copy(original)
      Marshal.load(Marshal.dump(original))
    end

    def process_node(node, context, path = [])
      if node.is_a?(Hash)
        @callbacks.each do |condition, callback|
          node = callback.call(node, context) if condition.call(path, node, context)
        end
        node = node.transform_values.with_index { |v, k| process_node(v, context, path + [node.keys[k]]) }
      elsif node.is_a?(Array)
        node = node.map { |v| process_node(v, context, path) }
      end

      node
    end

    def snake_case(str)
      str.gsub(/([a-z])([A-Z])/, '\1_\2').gsub(/([A-Z])([A-Z][a-z])/, '\1_\2').downcase
    end

    def yaml_to_terraform(yaml_data)
      type = yaml_data['type']
      name = yaml_data['name']
      resource_name = "konnect_#{snake_case(type)}"
      terraform = "resource \"#{resource_name}\" \"#{name.gsub('-', '_')}\" {\n"
      terraform += terraform_resource_prefix
      yaml_data.each do |key, value|
        next if key == 'mesh' # We use a reference at the end of the provider

        terraform += convert_to_terraform(key, value, 1)
      end
      terraform += terraform_resource_suffix
      terraform += "}\n"
      terraform
    end

    def terraform_resource_prefix
      <<-HEREDOC
  provider = konnect-beta
      HEREDOC
    end

    def terraform_resource_suffix
      <<-HEREDOC
  labels   = {
  "kuma.io/mesh" = konnect_mesh.my_mesh.name
  }
  cp_id    = konnect_mesh_control_plane.my_meshcontrolplane.id
  mesh     = konnect_mesh.my_mesh.name
      HEREDOC
    end

    def convert_to_terraform(key, value, indent_level, is_in_array = false, is_last = false)
      key = snake_case(key) unless key.empty?
      indent = '  ' * indent_level
      if value.is_a?(Hash)
        result = is_in_array ? "#{indent}{\n" : "#{indent}#{key} = {\n"
        value.each_with_index do |(k, v), index|
          result += convert_to_terraform(k, v, indent_level + 1, false, index == value.size - 1)
        end
        result += "#{indent}}#{is_in_array && !is_last ? ',' : ''}\n"
      elsif value.is_a?(Array)
        result = "#{indent}#{key} = [\n"
        value.each_with_index do |v, index|
          result += convert_to_terraform('', v, indent_level + 1, true, index == value.size - 1)
        end
        result += "#{indent}]#{is_in_array && !is_last ? ',' : ''}\n"
      else
        result = "#{indent}#{key} = \"#{value}\"#{is_in_array && !is_last ? ',' : ''}\n"
      end
      result
    end

    def render(context)
      content = super
      return '' if content == ''

      @site = context.registers[:site]
      @page = context.environments.first['page']

      @params.each do |k, v|
        next unless %w[use_meshservice namespace].include?(k)
        next unless v.is_a?(String)

        @params[k] = v.split('.').reduce(context) { |c, key| c[key] } || false
      end

      has_raw = @body.nodelist.first { |x| x.has?('tag_name') and x.tag_name == 'raw' }

      release = context.registers[:page]['release']
      # remove ```yaml header and ``` footer and read each document one by one
      content = content.gsub(/`{3}yaml\n/, '').gsub(/`{3}/, '')
      site_data = context.registers[:site].config

      use_meshservice = @params['use_meshservice'] == true && Gem::Version.new(release.number.dup.sub('x',
                                                                                                      '0')) >= TARGET_VERSION
      show_tf = Gem::Version.new(release.number.dup.sub('x', '0')) >= TF_TARGET_VERSION

      namespace = @params['namespace'] || site_data['mesh_namespace']
      styles = [
        { name: :uni_legacy, env: :universal, legacy_output: true },
        { name: :uni, env: :universal, legacy_output: false },
        { name: :kube_legacy, env: :kubernetes, legacy_output: true, namespace: namespace },
        { name: :kube, env: :kubernetes, legacy_output: false, namespace: namespace }
      ]

      contents = styles.map { |style| [style[:name], ''] }.to_h
      terraform_content = ''

      YAML.load_stream(content) do |yaml_data|
        styles.each do |style|
          processed_data = process_node(deep_copy(yaml_data), style)
          contents[style[:name]] += "\n---\n" unless contents[style[:name]] == ''
          contents[style[:name]] += YAML.dump(processed_data).gsub(/^---\n/, '').chomp
          terraform_content += yaml_to_terraform(processed_data) if style[:name] == :uni
        end
      end

      contents = contents.transform_values do |c|
        transformed = "```yaml\n#{c}\n```\n"
        transformed = "{% raw %}\n#{transformed}{% endraw %}\n" if has_raw
        transformed
      end
      terraform_content = "```hcl\n#{terraform_content}\n```\n"
      terraform_content = "{% raw %}\n#{terraform_content}{% endraw %}\n" if has_raw

      additional_classes = 'codeblock' unless use_meshservice

      # Return the final HTML content
      context.stack do
        context['additional_classes'] = additional_classes
        context['use_meshservice'] = use_meshservice
        context['show_tf'] = show_tf
        context['terraform_content'] = terraform_content
        context['kube_legacy'] = contents[:kube_legacy]
        context['kube'] = contents[:kube]
        context['uni_legacy'] = contents[:uni_legacy]
        context['uni'] = contents[:uni]
        context['heading_level'] = Jekyll::ClosestHeading.new(@page, @line_number, context).level
        ::Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    end

    def template
      File.read(File.join(@site.source, '_includes/components/policy_yaml.md'))
    end
  end
end

Liquid::Template.register_tag('policy_yaml', Jekyll::RenderPolicyYaml)
