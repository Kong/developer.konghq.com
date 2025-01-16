# frozen_string_literal: true

require 'json'
require_relative '../../lib/site_accessor'

module Jekyll
  module Drops
    module Validations
      class Base < Liquid::Drop # rubocop:disable Style/Documentation
        include Jekyll::SiteAccessor

        def self.make_for(name:, yaml:)
          case name
          when 'rate-limit-check'
            RateLimitCheck.new(name:, yaml:)
          when 'auth-check'
            AuthCheck.new(name:, yaml:)
          when 'request-check'
            RequestCheck.new(name:, yaml:)
          else
            raise ArgumentError, "Missing Drop for `#{name}`"
          end
        end

        attr_reader :name

        def initialize(name:, yaml:) # rubocop:disable Lint/MissingSuper
          @name = name
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
          @konnect_url ||= File.join(
            how_tos_config.dig('url_origin', 'konnect'), @yaml['url']
          ).to_s
        end

        def on_prem_url
          @on_prem_url ||= URI.join(
            how_tos_config.dig('url_origin', 'on_prem'), @yaml['url']
          ).to_s
        end

        def data_validate_konnect
          JSON.dump({ name: name, config: config.merge(url: konnect_url) })
        end

        def data_validate_on_prem
          JSON.dump({ name: name, config: config.merge(url: on_prem_url) })
        end

        def config
          @config ||= configuration.merge(@yaml.except('preamble', 'url'))
        end

        def template_file
          @template_file ||= "app/_includes/how-tos/validations/#{name}/index.html"
        end

        private

        def configuration
          @configuration ||= begin
            config = how_tos_config['validations'].detect { |v| v['name'] == name } || {}
            config.except('name')
          end
        end

        def how_tos_config
          @how_tos_config ||= site.data.dig('how-tos', 'config')
        end
      end
    end
  end
end
