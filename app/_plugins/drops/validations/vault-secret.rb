# frozen_string_literal: true

require 'json'
require_relative './base'

module Jekyll
  module Drops
    module Validations
      class VaultSecret < Base # rubocop:disable Style/Documentation
        def validate_yaml!
          raise ArgumentError, "Missing `url` in {% validation #{name} %}." unless @yaml.key?('url')
        end

        def method
          @method ||= @yaml['method']
        end
      end
    end
  end
end