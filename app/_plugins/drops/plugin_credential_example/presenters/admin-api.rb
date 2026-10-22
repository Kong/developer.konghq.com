# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    class PluginCredentialExample < Liquid::Drop
      module Presenters
        class AdminAPI < Base
          class Request < Liquid::Drop
            attr_reader :url, :data

            def initialize(url:, data:)
              @url = url
              @data = data
            end

            def headers
              []
            end
          end

          def consumer_request
            @consumer_request ||= Request.new(url: base_url + consumer_endpoint, data: consumer)
          end

          def credential_request
            @credential_request ||= Request.new(url: base_url + credential_path, data: credential['data'])
          end

          def template_file
            '/components/plugin_credential_example/format/admin-api.md'
          end

          private

          def base_url
            entity_examples_config['formats']['admin-api']['base_url']
          end

          def consumer_endpoint
            entity_examples_config['formats']['admin-api']['endpoints']['consumer']
          end
        end
      end
    end
  end
end
