# frozen_string_literal: true

require 'json'
require_relative '../../lib/site_accessor'

module Jekyll
  module Drops
    module Validations
      class Base < Liquid::Drop # rubocop:disable Style/Documentation
        include Jekyll::SiteAccessor

        def self.make_for(id:, yaml:)
          case id
          when 'rate-limit-check'
            RateLimitCheck.new(id:, yaml:)
          when 'unauthorized-check'
            UnauthorizedCheck.new(id:, yaml:)
          when 'request-check'
            RequestCheck.new(id:, yaml:)
          when 'grpc-check'
            GrpcCheck.new(id:, yaml:)
          when 'vault-secret'
            VaultSecret.new(id:, yaml:)
          when 'kubernetes-resource'
            KubernetesResource.new(id:, yaml:)
          when 'kubernetes-resource-property'
            KubernetesResourceProperty.new(id:, yaml:)
          when 'traffic-generator'
            TrafficGenerator.new(id:, yaml:)
          when 'env-variables'
            EnvVariables.new(id:, yaml:)
          when 'custom-command'
            CustomCommand.new(id:, yaml:)
          else
            raise ArgumentError, "Missing Drop for `#{id}`"
          end
        end

        attr_reader :id

        def initialize(id:, yaml:) # rubocop:disable Lint/MissingSuper
          @id = id
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
          base_url = how_tos_config.dig('url_origin', 'konnect')
          base_url = @yaml['konnect_url'] if @yaml['konnect_url']
          @konnect_url ||= File.join(
            base_url, @yaml['url']
          ).to_s
        end

        def on_prem_url
          base_url = how_tos_config.dig('url_origin', 'on_prem')
          base_url = @yaml['on_prem_url'] if @yaml['on_prem_url']
          @on_prem_url ||= File.join(
            base_url, @yaml['url']
          ).to_s
        end

        def data_validate_konnect
          JSON.dump({ name: id, config: config.merge(url: konnect_url) })
        end

        def data_validate_on_prem
          JSON.dump({ name: id, config: config.merge(url: on_prem_url) })
        end

        def config
          @config ||= configuration.merge(@yaml.except('url', 'section'))
        end

        def template_file
          @template_file ||= "app/_includes/how-tos/validations/#{id}/index.html"
        end

        def section
          @section ||= @yaml['section'] || 'step'
        end

        private

        def configuration
          @configuration ||= begin
            config = how_tos_config['validations'].detect { |v| v['id'] == id } || {}
            config.except('id')
          end
        end

        def how_tos_config
          @how_tos_config ||= site.data.dig('how-tos', 'config')
        end
      end
    end
  end
end
