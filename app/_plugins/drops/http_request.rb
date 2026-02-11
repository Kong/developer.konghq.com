# frozen_string_literal: true

require 'json'
require_relative '../lib/site_accessor'

module Jekyll
  module Drops
    class HttpRequest < Liquid::Drop # rubocop:disable Style/Documentation
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
        end
      end

      def config
        @config ||= @yaml
      end

      def template_file
        if @format == 'markdown'
          'app/_includes/http_request.md'
        else
          'app/_includes/http_request.html'
        end
      end

      def method
        @method ||= @yaml['method']
      end

      private

      def validate_yaml!
        raise ArgumentError, 'Missing `url` in {% http_request %}.' unless @yaml.key?('url')
      end
    end
  end
end
