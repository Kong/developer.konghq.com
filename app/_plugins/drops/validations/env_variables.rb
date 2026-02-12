# frozen_string_literal: true

require 'json'
require_relative './base'

module Jekyll
  module Drops
    module Validations
      class EnvVariables < Base # rubocop:disable Style/Documentation
        def variables
          @variables ||= @yaml.except('section')
        end

        def data_validate
          JSON.dump({ name: id, config: variables })
        end

        def validate_yaml!
          raise ArgumentError, "Missing variables in {% validation #{id} %}." if @yaml.empty?
        end
      end
    end
  end
end
