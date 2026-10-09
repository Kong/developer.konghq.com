# frozen_string_literal: true

module Jekyll
  module Drops
    class PluginCredentialExample < Liquid::Drop
      module Presenters
        class Base < Liquid::Drop
          def initialize(credential_example:)
            @credential_example = credential_example
          end

          def consumer
            @consumer ||= @credential_example.consumer
          end

          def credential
            @credential ||= @credential_example.credential
          end

          def plugin_name
            @plugin_name ||= @credential_example.plugin_name
          end

          private

          def site
            @site ||= Jekyll.sites.first
          end

          def entity_examples_config
            @entity_examples_config ||= site.data['entity_examples']['config']
          end

          def credential_path
            @credential_path ||= @credential_example.admin_api_path
          end
        end
      end
    end
  end
end
