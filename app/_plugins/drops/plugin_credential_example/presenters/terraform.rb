# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    class PluginCredentialExample < Liquid::Drop
      module Presenters
        class Terraform < Base
          CONSUMER_RESOURCE_NAME = 'konnect_gateway_consumer'
          CONSUMER_LOCAL_NAME = 'my_consumer'

          def consumer_resource_name
            CONSUMER_RESOURCE_NAME
          end

          def consumer_local_name
            CONSUMER_LOCAL_NAME
          end

          def credential_resource_name
            @credential_example.terraform_resource_name
          end

          def credential_local_name
            @credential_local_name ||= "my_#{credential['endpoint'].tr('-', '_')}"
          end

          def consumer_reference
            "#{consumer_resource_name}.#{consumer_local_name}.id"
          end

          def consumer_body
            @consumer_body ||= hcl_lines(consumer)
          end

          def credential_body
            @credential_body ||= begin
              lines = ["  consumer_id = #{consumer_reference}"]
              credential['data'].each { |key, value| lines << "  #{key} = #{quote(value)}" }
              lines.join("\n")
            end
          end

          def template_file
            '/components/plugin_credential_example/format/terraform.md'
          end

          private

          def hcl_lines(hash)
            hash.map { |key, value| "  #{key} = #{quote(value)}" }.join("\n")
          end

          def quote(value)
            return value.to_s if value.is_a?(Numeric) || [true, false].include?(value)

            "\"#{value}\""
          end
        end
      end
    end
  end
end
