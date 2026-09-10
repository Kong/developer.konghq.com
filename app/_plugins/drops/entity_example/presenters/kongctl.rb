# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module Kongctl
          class Base < Presenters::Base
            ENTITY_TO_CHILD_KEY = {
              'backend_cluster' => 'backend_clusters',
              'virtual_cluster' => 'virtual_clusters',
              'listener' => 'listeners',
              'static_key' => 'static_keys',
              'tls_trust_bundle' => 'tls_trust_bundles',
              'schema_registry' => 'schema_registries'
            }.freeze

            AI_GATEWAY_ENTITY_TO_CHILD_KEY = {
              'model' => 'models',
              'vault' => 'vaults',
              'model-provider' => 'model_providers',
              'agent' => 'agents',
              'consumer' => 'consumers',
              'consumer_group' => 'consumer_groups',
              'mcp_server' => 'mcp_servers',
              'auth-strategy' => 'auth_strategies',
              'policy' => 'policies'
            }.freeze

            def data
              @data ||= @example_drop.data
            end

            def config
              @config ||= apply_env_tags(yaml_config)
            end

            def missing_variables
              @missing_variables ||= begin
                base = if @example_drop.product == 'ai-gateway'
                         [formats['kongctl']['ai_gateway_variables']['ai_gateway']]
                       else
                         [formats['kongctl']['event_gateway_variables']['event_gateway']]
                       end
                base + variables.filter_map do |_key, var|
                  next unless var['description']

                  placeholder = Utils::VariableReplacer::KongctlData.apply_tags(
                    Utils::VariableReplacer::KongctlData.run(data: var['value'])
                  )
                  { 'placeholder' => placeholder, 'description' => var['description'] }
                end
              end
            end

            def template_file
              '/components/entity_example/format/kongctl.md'
            end

            def product
              @product ||= @example_drop.product
            end

            private

            def build_config_hash
              if @example_drop.product == 'ai-gateway'
                entity_item = { 'ref' => yaml_data['name'],
                                'ai_gateway' => Utils::VariableReplacer::KongctlData::AI_GATEWAY_LOOKUP_SENTINEL }.merge(yaml_data.except('ref'))
                { "ai_gateway_#{child_key}" => [entity_item] }
              else
                {
                  'event_gateways' => [
                    {
                      'ref' => event_gateway_placeholder,
                      'name' => event_gateway_placeholder,
                      child_key => [{ 'ref' => yaml_data['name'] }.merge(yaml_data)]
                    }
                  ]
                }
              end
            end

            def child_key
              map = if @example_drop.product == 'ai-gateway'
                      AI_GATEWAY_ENTITY_TO_CHILD_KEY
                    else
                      ENTITY_TO_CHILD_KEY
                    end

              map.fetch(entity_type) do
                raise ArgumentError,
                      "Unsupported kongctl entity_type `#{entity_type}`. Supported entity types: #{map.keys.join(', ')}"
              end
            end

            def yaml_config
              Jekyll::Utils::HashToYAML.new(build_config_hash).convert
            end

            def apply_env_tags(yaml)
              Utils::VariableReplacer::KongctlData.apply_tags(yaml)
            end

            def yaml_data
              @yaml_data ||= Utils::VariableReplacer::KongctlData.run(data: data, variables: variables)
            end

            def event_gateway_placeholder
              formats['kongctl']['event_gateway_variables']['event_gateway']['placeholder']
            end

            def ai_gateway_placeholder
              formats['kongctl']['ai_gateway_variables']['ai_gateway']['placeholder']
            end
          end

          class EventGatewayPolicy < Base
            def missing_variables
              @missing_variables ||= begin
                vars = [formats['kongctl']['event_gateway_variables']['event_gateway']]
                vars << if policy_target == 'listener'
                          formats['kongctl']['event_gateway_variables']['listener']
                        else
                          formats['kongctl']['event_gateway_variables']['virtual_cluster']
                        end
                vars
              end
            end

            private

            def yaml_config
              if policy_target == 'listener'
                Jekyll::Utils::HashToYAML.new(build_listener_policy_hash).convert
              else
                Jekyll::Utils::HashToYAML.new(build_virtual_cluster_policy_hash).convert
              end
            end

            def policy_target
              @example_drop.policy_target
            end

            def phase_key
              "#{@example_drop.target.key}_policies"
            end

            def policy_item
              type = data['type']
              {
                'ref' => yaml_data['name'],
                'type' => type,
                type => yaml_data.except('type')
              }.compact
            end

            def virtual_cluster_placeholder
              formats['kongctl']['event_gateway_variables']['virtual_cluster']['placeholder']
            end

            def listener_placeholder
              formats['kongctl']['event_gateway_variables']['listener']['placeholder']
            end

            def build_virtual_cluster_policy_hash
              {
                'event_gateways' => [
                  {
                    'ref' => event_gateway_placeholder,
                    'name' => event_gateway_placeholder,
                    'virtual_clusters' => [
                      {
                        'ref' => virtual_cluster_placeholder,
                        'name' => virtual_cluster_placeholder,
                        phase_key => [policy_item]
                      }
                    ]
                  }
                ]
              }
            end

            def build_listener_policy_hash
              {
                'event_gateways' => [
                  {
                    'ref' => event_gateway_placeholder,
                    'name' => event_gateway_placeholder,
                    'listeners' => [
                      {
                        'ref' => listener_placeholder,
                        'name' => listener_placeholder,
                        'policies' => [policy_item]
                      }
                    ]
                  }
                ]
              }
            end
          end
        end
      end
    end
  end
end
