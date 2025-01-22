# frozen_string_literal: true

require 'json'
require_relative '../lib/site_accessor'

module Jekyll
  module Drops
    class ControlPlaneRequest < Liquid::Drop # rubocop:disable Style/Documentation
      include Jekyll::SiteAccessor

      attr_reader :name

      def initialize(yaml:) # rubocop:disable Lint/MissingSuper
        @yaml = yaml
        @name = 'request-check'

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

      def konnect_url
        @konnect_url ||= File.join(
          configuration.dig('url_origin', 'konnect'), @yaml['url']
        ).to_s
      end

      def on_prem_url
        @on_prem_url ||= URI.join(
          configuration.dig('url_origin', 'on_prem'), @yaml['url']
        ).to_s
      end

      def data_validate_konnect
        JSON.dump({ name: name, config: config.merge(url: konnect_url) })
      end

      def data_validate_on_prem
        JSON.dump({ name: name, config: config.merge(url: on_prem_url) })
      end

      def config
        @config ||= @yaml.except('url')
      end

      def template_file
        # re-use request-check so that the data-attributes are rendered
        @template_file ||= 'app/_includes/how-tos/validations/request-check/index.html'
      end

      def method
        @method ||= @yaml['method']
      end

      private

      def configuration
        @configuration ||= site.data['control_plane_request']
      end

      def validate_yaml!
        raise ArgumentError, 'Missing `url` in {% control_plane_request %}.' unless @yaml.key?('url')

        raise ArgumentError, 'Missing `status_code` in {% control_plane_request %}.' unless @yaml.key?('status_code')
      end
    end
  end
end
