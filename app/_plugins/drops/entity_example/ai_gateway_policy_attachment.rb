# frozen_string_literal: true

require_relative 'base'

module Jekyll
  module Drops
    module EntityExample
      class AIGatewayPolicyAttachment < Base
        TARGET_ENTITY_TYPES = {
          'ai-model' => 'model',
          'ai-agent' => 'agent',
          'ai-mcp-server' => 'mcp_server',
          'ai-consumer' => 'consumer',
          'ai-consumer-group' => 'consumer_group'
        }.freeze

        DEFAULT_CONFIG_NAME = 'basic'

        def initialize(example:, **options)
          super
          config_body
        end

        def entity_type
          @entity_type ||= TARGET_ENTITY_TYPES.fetch(target.key)
        end

        def formats
          @formats ||= super.sort_by { |format| @example.formats.index(format) }
        end

        def policy_name
          @policy_name ||= @example.data['name']
        end

        def target
          @target ||= PluginTarget.new(
            target: OpenStruct.new(key: @options[:target], value: @options[:target])
          )
        end

        def data
          @data ||= config_body.merge('policies' => composed_policies)
        end

        def variables
          @variables ||= @example.raw_variables
        end

        private

        def config_name
          @config_name ||= @example.attach.fetch(target.key, DEFAULT_CONFIG_NAME)
        end

        def config_body
          @config_body ||= begin
            body = site.data.dig('entity_examples', 'ai-gateway', target.key, config_name)
            raise ArgumentError, missing_config_error unless body

            body
          end
        end

        def composed_policies
          config_policies = config_body['policies'] || []
          (config_policies + [policy_name]).uniq
        end

        def missing_config_error
          "Missing `attach` config for target `#{target.key}`: " \
            "app/_data/entity_examples/ai-gateway/#{target.key}/#{config_name}.yml"
        end

        def site
          @site ||= Jekyll.sites.first
        end
      end
    end
  end
end
