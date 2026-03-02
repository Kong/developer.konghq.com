# frozen_string_literal: true

require 'json'
require_relative './base'

module Jekyll
  module Drops
    module Validations
      class KubernetesWaitFor < Base # rubocop:disable Style/Documentation
        def validate_yaml!
          raise ArgumentError, "Missing `kind` in {% validation #{id} %}." unless @yaml.key?('kind')
          raise ArgumentError, "Missing `resource` in {% validation #{id} %}." unless @yaml.key?('resource')
        end

        def data_validate
          JSON.dump({ name: id, config: config })
        end
      end
    end
  end
end
