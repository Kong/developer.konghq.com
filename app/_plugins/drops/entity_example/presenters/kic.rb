# frozen_string_literal: true

require_relative './base'

FOREIGN_KEYS = %w[
  service
  route
  consumer
  consumer_group
  global
].freeze

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module KIC
          class Base < Presenters::Base
            attr_reader :other_plugins, :foreign_key_names, :foreign_keys, :full_resource, :skip_annotate

            def initialize(example_drop:)
              super(example_drop:)
              @foreign_keys = []
              @foreign_key_names = {}
              @other_plugins = ''
              @skip_annotate = false
            end

            def data
              @data ||= Utils::VariableReplacer::Data.run(
                data: @example_drop.data,
                variables: variables
              )
            end

            def custom_template
              p = "components/entity_example/format/snippets/kic/#{entity_type}.md"
              File.exist?(site.in_source_dir("_includes/#{p}")) ? p : nil
            end

            def template_file
              '/components/entity_example/format/kic.md'
            end

            def k8s_entity_type
              @k8s_entity_type ||= entity_type.split('_').map(&:capitalize).join
            end

            def remove_foreign_keys(d)
              FOREIGN_KEYS.each do |key|
                next unless d.key?(key)

                camel_case_key = key.split('_').map(&:capitalize).join
                @foreign_key_names[camel_case_key] = d[key]
                @foreign_keys << camel_case_key if key != 'global'
                d.delete(key)
              end
              @foreign_keys = @foreign_keys.uniq.compact
            end

            def targets
              keys = foreign_keys.map do |key|
                next '`service`' if key == 'Service'
                next '`httproute` or `ingress`' if key == 'Route'

                "`Kong#{key}`"
              end
              last_key = keys.pop
              str = keys.join(', ')
              str = str.empty? ? last_key : "#{str} and #{last_key}"
              "#{str} resource#{'s' if foreign_keys.size > 1}"
            end

            def render
              d = data

              if d['tags']
                tags = d['tags']
                d.delete('tags')
              end

              if d['skip_annotate']
                @skip_annotate = d['skip_annotate']
                d.delete('skip_annotate')
              end

              # Remove foreign keys
              remove_foreign_keys(d)

              if d.key?('other_plugins')
                @other_plugins = d['other_plugins']
                @other_plugins += ',' if @other_plugins
                d.delete('other_plugins')
              end

              resource_type = k8s_entity_type
              resource_type = 'ClusterPlugin' if resource_type == 'Plugin' && foreign_keys.size == 0

              r = {
                'apiVersion' => 'configuration.konghq.com/v1',
                'kind' => "Kong#{resource_type}",
                'metadata' => {
                  'name' => d['name'] || d['username'],
                  'namespace' => 'kong',
                  'annotations' => {
                    'kubernetes.io/ingress.class' => 'kong'
                  }
                }
              }

              if %w[Plugin ClusterPlugin].include?(resource_type)
                d['plugin'] = d['name'] if d['name'] && !d['plugin']
                d.delete('name')
              end

              r = r.merge(d)

              r['metadata']['annotations']['konghq.com/tags'] = tags.join(', ') if tags
              if resource_type == 'ClusterPlugin'
                r['metadata']['labels'] = r['metadata']['labels'] || {}
                r['metadata']['labels']['global'] = 'true'
              end

              @full_resource = r
              @full_resource.to_yaml
            end

            def to_s
              render.split("\n").slice(1..-1).join("\n").strip
            end
          end

          class Plugin < Base
          end
        end
      end
    end
  end
end
