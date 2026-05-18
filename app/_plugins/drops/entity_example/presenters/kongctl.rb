# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module Kongctl
          class Base < Presenters::Base
            ENTITY_TO_CHILD_KEY = {
              'backend_cluster'  => 'backend_clusters',
              'virtual_cluster'  => 'virtual_clusters',
              'listener'         => 'listeners',
              'static_key'       => 'static_keys',
              'tls_trust_bundle' => 'tls_trust_bundles',
              'schema_registry'  => 'schema_registries'
            }.freeze

            def data
              @data ||= @example_drop.data
            end

            def config
              @config ||= Jekyll::Utils::HashToYAML.new(build_config_hash).convert
            end

            def missing_variables
              @missing_variables ||= [formats['kongctl']['event_gateway_variables']['event_gateway']]
            end

            def template_file
              '/components/entity_example/format/kongctl.md'
            end

            private

            def build_config_hash
              {
                'event_gateways' => [
                  {
                    'ref'  => event_gateway_placeholder,
                    'name' => event_gateway_placeholder,
                    child_key => [{ 'ref' => data['name'] }.merge(data)]
                  }
                ]
              }
            end

            def child_key
              ENTITY_TO_CHILD_KEY.fetch(entity_type) do
                raise ArgumentError,
                      "Unsupported kongctl entity_type `#{entity_type}`. Supported entity types: #{ENTITY_TO_CHILD_KEY.keys.join(', ')}"
              end
            end

            def event_gateway_placeholder
              formats['kongctl']['event_gateway_variables']['event_gateway']['placeholder']
            end
          end

          class EventGatewayPolicy < Base
            def config
              @config ||= if policy_target == 'listener'
                            Jekyll::Utils::HashToYAML.new(build_listener_policy_hash).convert
                          else
                            Jekyll::Utils::HashToYAML.new(build_virtual_cluster_policy_hash).convert
                          end
            end

            def missing_variables
              @missing_variables ||= begin
                vars = [formats['kongctl']['event_gateway_variables']['event_gateway']]
                if policy_target == 'listener'
                  vars << formats['kongctl']['event_gateway_variables']['listener']
                else
                  vars << formats['kongctl']['event_gateway_variables']['virtual_cluster']
                end
                vars
              end
            end

            private

            def policy_target
              @example_drop.policy_target
            end

            def phase_key
              "#{@example_drop.target.key}_policies"
            end

            def policy_item
              {
                'ref'           => data['name'],
                'type'          => data['type'],
                data['type']    => data.except('type')
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
                    'ref'              => event_gateway_placeholder,
                    'name'             => event_gateway_placeholder,
                    'virtual_clusters' => [
                      {
                        'ref'    => virtual_cluster_placeholder,
                        'name'   => virtual_cluster_placeholder,
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
                    'ref'       => event_gateway_placeholder,
                    'name'      => event_gateway_placeholder,
                    'listeners' => [
                      {
                        'ref'      => listener_placeholder,
                        'name'     => listener_placeholder,
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
