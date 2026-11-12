# frozen_string_literal: true

require_relative './base'
require_relative './admin-api'
require_relative '../../entity_example/utils/variable_replacer'

module Jekyll
  module Drops
    class PluginCredentialExample < Liquid::Drop
      module Presenters
        class KonnectAPI < Base
          class Request < AdminAPI::Request
            attr_reader :pat

            def initialize(url:, data:, pat:)
              super(url: url, data: data)
              @pat = pat
            end
          end

          def consumer_request
            @consumer_request ||= Request.new(url: base_url + consumer_endpoint, data: consumer, pat: pat)
          end

          def credential_request
            @credential_request ||= Request.new(url: base_url + credential_path, data: credential['data'], pat: pat)
          end

          def missing_variables
            @missing_variables ||= [variables['region'], variables['control_plane']]
          end

          def template_file
            '/components/plugin_credential_example/format/konnect-api.md'
          end

          private

          def pat
            variables['pat']['placeholder']
          end

          def base_url
            @base_url ||= EntityExample::Utils::VariableReplacer::URL.run(
              url: entity_examples_config['formats']['konnect-api']['base_url'],
              defaults: variables,
              variables: {}
            )
          end

          def consumer_endpoint
            entity_examples_config['formats']['konnect-api']['endpoints']['consumer']
          end

          def variables
            @variables ||= entity_examples_config['formats']['konnect-api']['variables']
          end
        end
      end
    end
  end
end
