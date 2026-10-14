# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    class PluginCredentialExample < Liquid::Drop
      module Presenters
        class Deck < Base
          def config
            @config ||= Jekyll::Utils::HashToYAML.new(
              { 'consumers' => [consumer_data] }
            ).convert
          end

          def template_file
            '/components/plugin_credential_example/format/deck.md'
          end

          private

          def consumer_data
            consumer.merge(credential['deck_key'] => [credential['data']])
          end
        end
      end
    end
  end
end
