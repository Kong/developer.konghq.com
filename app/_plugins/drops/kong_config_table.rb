# frozen_string_literal: true

require 'yaml'

require_relative '../lib/site_accessor'

module Jekyll
  module Drops
    class KongConfigTable < Liquid::Drop # rubocop:disable Style/Documentation
      class KongConfigField < Liquid::Drop # rubocop:disable Style/Documentation
        def initialize(config, field) # rubocop:disable Lint/MissingSuper
          @config = config
          @field = field || {}
        end

        def name
          @name ||= @config.fetch('name')
        end

        def default_value
          @default_value ||= @field.fetch('default_value')
        end

        def description
          @description ||= @config['description'] || @field['description']
        end
      end

      include Jekyll::SiteAccessor

      def initialize(config, release_number) # rubocop:disable Lint/MissingSuper
        @config = config
        @release_number = release_number
      end

      def fields
        @fields ||= @config.map { |c| KongConfigField.new(c, kong_conf[c['name']]) }
      end

      def kong_conf
        @kong_conf ||= site.data.dig('kong-conf', @release_number.gsub('.', ''))
      end
    end
  end
end
