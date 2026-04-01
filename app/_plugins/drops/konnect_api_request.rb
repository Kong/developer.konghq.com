# frozen_string_literal: true

require 'json'
require_relative '../lib/site_accessor'

module Jekyll
  module Drops
    class KonnectApiRequest < Liquid::Drop # rubocop:disable Style/Documentation
      include Jekyll::SiteAccessor

      def initialize(yaml:, format:) # rubocop:disable Lint/MissingSuper
        @yaml = yaml
        @format = format

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

      def data_validate_konnect
        JSON.dump({ name: 'konnect-api-request', config: config.merge(url: url) })
      end

      def url
        "https://#{self['region']}.api.konghq.com#{@yaml['url']}"
      end

      def headers
        @headers ||= begin
          h = @yaml['headers'] || []
          h.unshift('Authorization: Bearer $KONNECT_TOKEN')
          h.uniq
        end
      end

      def config
        @config ||= @yaml.merge('headers' => headers)
      end

      def template_file
        if @format == 'markdown'
          'app/_includes/konnect_api_request.md'
        else
          'app/_includes/konnect_api_request.html'
        end
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
