# frozen_string_literal: true

require 'json'
require_relative './base'

module Jekyll
  module Drops
    module Validations
      class CustomCommand < Base # rubocop:disable Style/Documentation
        def validate_yaml!
          raise ArgumentError, "Missing `command` in {% validation #{id} %}." unless @yaml.key?('command')
          raise ArgumentError, "Missing `expected` in {% validation #{id} %}." unless @yaml.key?('expected')
        end

        def data_validate
          JSON.dump({ name: id, config: config })
        end
      end
    end
  end
end
