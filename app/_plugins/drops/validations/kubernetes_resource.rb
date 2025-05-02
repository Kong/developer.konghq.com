# frozen_string_literal: true

require 'json'
require_relative './base'

module Jekyll
  module Drops
    module Validations
      class KubernetesResource < Base # rubocop:disable Style/Documentation
        def validate_yaml!
          raise ArgumentError, "Missing `kind` in {% validation #{id} %}." unless @yaml.key?('kind')
          raise ArgumentError, "Missing `name` in {% validation #{id} %}." unless @yaml.key?('name')
        end

        def data_validate_konnect
          JSON.dump({ name: id, config: config })
        end

        def data_validate_on_prem
          JSON.dump({ name: id, config: config })
        end
      end
    end
  end
end
