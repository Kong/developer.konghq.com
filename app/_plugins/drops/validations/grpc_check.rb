# frozen_string_literal: true

require 'json'
require_relative './base'

module Jekyll
  module Drops
    module Validations
      class GrpcCheck < Base # rubocop:disable Style/Documentation
        def validate_yaml!
          raise ArgumentError, "Missing `method` in {% validation #{name} %}." unless @yaml.key?('method')
        end

        def konnect_url
          base_url = how_tos_config.dig('url_origin', 'konnect')
          base_url = @yaml['konnect_url'] if @yaml['konnect_url']
          base_url
        end

        def on_prem_url
          base_url = how_tos_config.dig('url_origin', 'on_prem')
          base_url = @yaml['on_prem_url'] if @yaml['on_prem_url']
          base_url
        end

        def method
          @method ||= @yaml['method']
        end
      end
    end
  end
end
