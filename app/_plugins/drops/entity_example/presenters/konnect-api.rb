# frozen_string_literal: true

require_relative '../utils/variable_replacer'
require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module KonnectAPI
          class Base < Presenters::Base
            def url
              @url ||= Utils::VariableReplacer::URL.run(
                url: build_url,
                defaults: default_variables,
                variables: variables
              )
            end

            def data
              @data ||= @example_drop.data
            end

            def template_file
              '/components/entity_example/format/konnect-api.md'
            end

            def pat
              @pat ||= variables['pat'] || "#{formats['konnect-api']['variables']['pat']['placeholder']}"
            end

            def missing_variables
              @missing_variables ||= begin
                available_variables = default_variables.except(*targets.keys, 'upstream')
                available_variables.except(*variables.keys).values
              end
            end

            private

            def default_variables
              @default_variables ||= formats['konnect-api']['variables']
            end

            def build_url
              [
                formats['konnect-api']['base_url'],
                formats['konnect-api']['endpoints'][entity_type]
              ].join
            end
          end

          class Plugin < Base
            def data
              @data ||= Utils::VariableReplacer::Data.run(
                data: @example_drop.data.except(*targets.keys),
                variables: variables
              )
            end

            def variables
              super.merge(@example_drop.target.key => @example_drop.target.value)
            end

            def missing_variables
              @missing_variables ||= begin
                missing = super

                if @example_drop.target.key == 'global'
                  missing
                elsif variables[@example_drop.target.key]
                  missing
                else
                  missing << formats['konnect-api']['variables'][@example_drop.target.key]
                end
              end
            end

            def build_url
              [
                formats['konnect-api']['base_url'],
                formats['konnect-api']['plugin_endpoints'][@example_drop.target.key]
              ].join
            end
          end

          class EventGatewayPolicy < Base
            def default_variables
              @default_variables ||= formats['konnect-api']['event_gateway_variables']
            end

            def build_url
              [
                formats['konnect-api']['event_gateway_base_url'],
                formats['konnect-api']['policy_endpoints'][@example_drop.target.key]
              ].join
            end
          end
        end
      end
    end
  end
end
