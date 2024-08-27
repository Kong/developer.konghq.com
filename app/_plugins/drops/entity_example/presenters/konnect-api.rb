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
                defaults: formats['konnect-api']['variables'],
                variables: variables
              )
            end

            def data
              @data ||= @example_drop.data
            end

            def template_file
              '/components/entity_example/format/konnect-api.md'
            end

            private

            def build_url
              [
                formats['konnect-api']['base_url'],
                formats['konnect-api']['endpoints'][entity_type]
              ].join
            end
          end

          class Plugin < Base
            def data
              @example_drop.data.except(*targets.keys)
            end

            def variables
              super.merge(@example_drop.target.key => @example_drop.target.value)
            end

            def build_url
              [
                formats['konnect-api']['base_url'],
                formats['konnect-api']['plugin_endpoints'][@example_drop.target.key]
              ].join
            end
          end
        end
      end
    end
  end
end
