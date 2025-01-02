# frozen_string_literal: true

require 'json'
require_relative '../../lib/site_accessor'

module Jekyll
  module Drops
    module Validations
      class RateLimitCheck < Liquid::Drop # rubocop:disable Style/Documentation
        include Jekyll::SiteAccessor

        def initialize(yaml_block) # rubocop:disable Lint/MissingSuper
          @yaml_block = yaml_block

          validate_yaml_block!
        end

        def [](key)
          key = key.to_s
          if respond_to?(key)
            public_send(key)
          elsif @yaml_block.key?(key)
            @yaml_block[key]
          elsif configuration.key?(key)
            configuration[key]
          end
        end

        def iterations
          @iterations ||= @yaml_block['iterations']
        end

        def konnect_url
          @konnect_url ||= File.join(
            how_tos_config.dig('url_origin', 'konnect'), @yaml_block['url']
          ).to_s
        end

        def on_prem_url
          @on_prem_url ||= URI.join(
            how_tos_config.dig('url_origin', 'on_prem'), @yaml_block['url']
          ).to_s
        end

        def headers
          @headers ||= @yaml_block['headers']
        end

        def message
          @message ||= configuration.fetch('message')
        end

        def data_validate_konnect
          JSON.dump({
                      name:,
                      config: {
                        iterations:,
                        headers:,
                        message:,
                        url: konnect_url
                      }
                    })
        end

        def data_validate_on_prem
          JSON.dump({
                      name:,
                      config: {
                        iterations:,
                        headers:,
                        message:,
                        url: on_prem_url
                      }
                    })
        end

        private

        def validate_yaml_block!
          raise ArgumentError, "Missing `iterations` in {% validation #{name} %}." unless @yaml_block.key?('iterations')

          return if @yaml_block.key?('url')

          raise ArgumentError, "Missing `url` in {% validation #{name} %}."
        end

        def name
          @name ||= 'rate-limit-check'
        end

        def configuration
          @configuration ||= begin
            config = how_tos_config['validations'].detect { |v| v['name'] == name }
            raise ArgumentError, "Missing yaml_block for `#{name}` in data/how-tos/validations.yaml" unless config

            config
          end
        end

        def how_tos_config
          @how_tos_config ||= site.data.dig('how-tos', 'config')
        end
      end
    end
  end
end
