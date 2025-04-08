# frozen_string_literal: true

require 'json'
require_relative './base'

module Jekyll
  module Drops
    module Validations
      class RateLimitCheck < Base # rubocop:disable Style/Documentation
        def validate_yaml!
          raise ArgumentError, "Missing `iterations` in {% validation #{name} %}." unless @yaml.key?('iterations')

          if @yaml.key?('grep') && !@yaml['output']&.key?('expected')
            raise ArgumentError,
                  'output.expected must be provided if `grep` is specified'
          end

          return if @yaml.key?('url')

          raise ArgumentError, "Missing `url` in {% validation #{name} %}."
        end
      end
    end
  end
end
