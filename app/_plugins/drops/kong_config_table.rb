# frozen_string_literal: true

require 'yaml'

require_relative '../lib/site_accessor'

module Jekyll
  module Drops
    class KongConfigTable < Liquid::Drop # rubocop:disable Style/Documentation
      class KongConfigField < Liquid::Drop # rubocop:disable Style/Documentation
        def initialize(config, field, mode) # rubocop:disable Lint/MissingSuper
          @config = config
          @field = field || {}
          @mode = mode

          @mode = 'conf' if mode.empty?
        end

        def name
          @name ||= format_name(@config.fetch('name'), @mode)
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

        def format_name(name, mode)
          return name if mode == 'conf'
          return "KONG_#{name.upcase}" if mode == 'env'

          raise "Unknown kong_config_table mode: #{mode}"
        end
      end

      include Jekyll::SiteAccessor

      def initialize(config, release_number, mode) # rubocop:disable Lint/MissingSuper
        @config = config
        @release_number = release_number
        @mode = mode

        validate_config!
      end

      def fields
        @fields ||= (params + directives).sort_by(&:name)
      end

      def params
        @params ||= @config.fetch('config', []).map { |c| KongConfigField.new(c, kong_conf['params'][c['name']], @mode) }
      end

      def directives
        @directives ||= @config.fetch('directives', []).map do |c|
          KongConfigField.new(c, kong_conf['params'][c['name']], @mode)
        end
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
