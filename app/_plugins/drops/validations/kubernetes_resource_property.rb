# frozen_string_literal: true

require 'json'
require_relative './base'

module Jekyll
  module Drops
    module Validations
      class KubernetesResourceProperty < Base # rubocop:disable Style/Documentation
        def validate_yaml!
          raise ArgumentError, "Missing `kind` in {% validation #{id} %}." unless @yaml.key?('kind')
          raise ArgumentError, "Missing `name` or `name_selector` in {% validation #{id} %}." unless @yaml.key?('name') || @yaml.key?('name_selector')
          raise ArgumentError, "Missing `path` in {% validation #{id} %}." unless @yaml.key?('path')
        end

        def data_validate
          JSON.dump({ name: id, config: config })
        end
      end
    end
  end
end
