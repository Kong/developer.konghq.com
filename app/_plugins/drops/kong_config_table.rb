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
          @default_value ||= @field['defaultValue']
        end

        def array?
          default_value&.is_a?(Array)
        end

        def description
          @description ||= @config['description'] || @field['description']
        end
      end

      include Jekyll::SiteAccessor

      def initialize(config, release_number) # rubocop:disable Lint/MissingSuper
        @config = config
        @release_number = release_number

        validate_config!
      end

      def fields
        @fields ||= (params + directives).sort_by(&:name)
      end

      def params
        @params ||= @config.fetch('config', []).map { |c| KongConfigField.new(c, kong_conf[c['name']]) }
      end

      def directives
        @directives ||= @config.fetch('directives', []).map { |c| KongConfigField.new(c, kong_conf[c['name']]) }
      end

      def kong_conf
        @kong_conf ||= site.data.dig('kong-conf', @release_number.gsub('.', ''))
      end

      private

      def validate_config!
        @config.fetch('directives', []).each do |d|
          unless d.key?('description')
            raise ArgumentError,
                  "Missing description for directive `#{d}` in kong_config_table"
          end
        end
      end
    end
  end
end
