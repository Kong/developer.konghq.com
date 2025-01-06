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
            def initialize(example_drop:)
              super(example_drop:)
              @foreign_keys = []
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

            attr_reader :foreign_keys

            def remove_foreign_keys(d)
              FOREIGN_KEYS.each do |key|
                next unless d.key?(key)

                d.delete(key)
                camel_case_key = key.split('_').map(&:capitalize).join
                @foreign_keys << camel_case_key if key != 'global'
              end
              @foreign_keys = @foreign_keys.uniq.compact
            end

            def targets
              keys = foreign_keys.map do |key|
                next '`service`' if key == 'Service'
                next '`ingress`' if key == 'Route'

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

              # Remove foreign keys
              remove_foreign_keys(d)

              resource_type = k8s_entity_type
              resource_type = 'ClusterPlugin' if resource_type == 'Plugin' && foreign_keys.size == 0

              d = {
                'apiVersion' => 'configuration.konghq.com/v1',
                'kind' => "Kong#{resource_type}",
                'metadata' => {
                  'name' => d['name'],
                  'annotations' => {
                    'kubernetes.io/ingress.class' => 'kong'
                  }
                }
              }.merge(d)

              d['metadata']['annotations']['konghq.com/tags'] = tags.join(', ') if tags

              d.to_yaml
            end

            def to_s
              render.strip
            end
          end

          class Plugin < Base
          end
        end
      end
    end
  end
end
