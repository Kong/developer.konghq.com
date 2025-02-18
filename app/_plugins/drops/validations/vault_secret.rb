# frozen_string_literal: true

require 'json'
require_relative './base'

module Jekyll
  module Drops
    module Validations
      class VaultSecret < Base # rubocop:disable Style/Documentation
        def validate_yaml!
          %w[secret value].each do |key|
            raise ArgumentError, "Missing `#{key}` in {% validation #{name} %}." unless @yaml.key?(key)
          end
        end

        def data_validate_konnect
          JSON.dump({ name: name, config: config.merge(container: container['konnect']) })
        end

        def data_validate_on_prem
          JSON.dump({ name: name, config: config.merge(container: container['on_prem']) })
        end

        def container
          @container ||= how_tos_config.fetch('container')
        end
      end
    end
  end
end
