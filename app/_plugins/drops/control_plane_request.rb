# frozen_string_literal: true

require 'json'
require_relative '../lib/site_accessor'

module Jekyll
  module Drops
    class ControlPlaneRequest < Liquid::Drop # rubocop:disable Style/Documentation
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

      def konnect_url
        base_url = configuration.dig('url_origin', 'konnect')
        base_url = @yaml['konnect_url'] if @yaml['konnect_url']
        @konnect_url ||= File.join(
          base_url, @yaml['url']
        ).to_s
      end

      def on_prem_url
        base_url = configuration.dig('url_origin', 'on_prem')
        base_url = @yaml['on_prem'] if @yaml['on_prem_url']
        @on_prem_url ||= File.join(
          base_url, @yaml['url']
        ).to_s
      end

      def config
        @config ||= @yaml.except('url')
      end

      def template_file
        @template_file ||= 'app/_includes/control_plane_request.html'
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
      end
    end
  end
end
