# frozen_string_literal: true

require 'json'
require_relative './base'

module Jekyll
  module Drops
    module Validations
      class TrafficGenerator < Base # rubocop:disable Style/Documentation
        def validate_yaml!
          raise ArgumentError, "Missing `iterations` in {% validation #{id} %}." unless @yaml.key?('iterations')

          return if @yaml.key?('url')

          raise ArgumentError, "Missing `url` in {% validation #{id} %}."
        end

        def snippet_config_overrides
          { 'count' => self['iterations'] }
        end

        def method
          @method ||= @yaml['method']
        end
      end
    end
  end
end
