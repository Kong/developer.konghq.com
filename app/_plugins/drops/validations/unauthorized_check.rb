# frozen_string_literal: true

require 'json'
require_relative './base'

module Jekyll
  module Drops
    module Validations
      class UnauthorizedCheck < Base # rubocop:disable Style/Documentation
        def validate_yaml!
          return if @yaml.key?('url')

          raise ArgumentError, "Missing `url` in {% validation #{id} %}."
        end
      end
    end
  end
end
