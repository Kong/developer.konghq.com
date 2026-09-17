# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    class PluginCredentialExample < Liquid::Drop
      module Presenters
        class KIC < Base
          def secret_name
            @secret_name ||= "#{consumer['username']}-#{credential['endpoint']}"
          end

          def template_file
            '/components/plugin_credential_example/format/kic.md'
          end
        end
      end
    end
  end
end
