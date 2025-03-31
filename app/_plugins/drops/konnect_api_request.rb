# frozen_string_literal: true

require 'json'
require_relative '../lib/site_accessor'

module Jekyll
  module Drops
    class KonnectApiRequest < Liquid::Drop # rubocop:disable Style/Documentation
      include Jekyll::SiteAccessor

      def initialize(yaml:) # rubocop:disable Lint/MissingSuper
        @yaml = yaml

        validate_yaml!
      end

      def [](key)
        key = key.to_s
        if respond_to?(key)
          public_send(key)
        elsif @yaml.key?(key)
          @yaml[key]
        elsif configuration.key?(key)
          configuration[key]
        end
      end

      def url
        "https://#{configuration['region']}.api.konghq.com#{@yaml['url']}"
      end

      def headers
        h = @yaml['headers'] || []
        h.unshift('Authorization: Bearer $KONNECT_TOKEN')
        h
      end

      def config
        @config ||= @yaml 
      end

      def template_file
        @template_file ||= 'app/_includes/konnect_api_request.html'
      end

      def method
        @method ||= @yaml['method']
      end

      private

      def configuration
        @configuration ||= site.data['konnect_api_request']
      end

      def validate_yaml!
        raise ArgumentError, 'Missing `url` in {% konnect_api_request %}.' unless @yaml.key?('url')
      end
    end
  end
end
