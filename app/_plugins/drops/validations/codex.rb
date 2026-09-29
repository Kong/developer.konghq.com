# frozen_string_literal: true

require 'json'
require_relative './base'

module Jekyll
  module Drops
    module Validations
      class Codex < Base # rubocop:disable Style/Documentation
        REQUIRED_FIELDS = %w[
          prompt model model_provider model_provider_name
          model_provider_base_url model_provider_env_key model_provider_wire_api
        ].freeze

        def validate_yaml!
          REQUIRED_FIELDS.each do |field|
            raise ArgumentError, "Missing `#{field}` in {% validation #{id} %}." unless @yaml.key?(field)
          end
        end

        def data_validate
          JSON.dump({ name: id, config: config })
        end

        def config
          @config ||= configuration.merge('command' => command, 'base_command' => base_command, 'flags' => flags)
        end

        def base_command
          @base_command ||= configuration.fetch('command')
        end

        def command
          @command ||= [
            configuration.fetch('command'),
            "exec \"#{prompt}\"",
            *flags.map { |flag| "-c #{flag}" },
            '--skip-git-repo-check'
          ].join(' ')
        end

        def flags
          [
            "model=\"#{model}\"",
            "model_provider=\"#{provider}\"",
            "model_providers.#{provider}.name=\"#{name}\"",
            "model_providers.#{provider}.base_url=\"#{base_url}\"",
            "model_providers.#{provider}.env_key=\"#{env_key}\"",
            "model_providers.#{provider}.wire_api=\"#{wire_api}\""
          ]
        end

        private

        def prompt
          @prompt ||= @yaml.fetch('prompt')
        end

        def model
          @model ||= @yaml.fetch('model')
        end

        def provider
          @provider ||= @yaml.fetch('model_provider')
        end

        def name
          @name ||= @yaml.fetch('model_provider_name')
        end

        def base_url
          @base_url ||= @yaml.fetch('model_provider_base_url')
        end

        def env_key
          @env_key ||= @yaml.fetch('model_provider_env_key')
        end

        def wire_api
          @wire_api ||= @yaml.fetch('model_provider_wire_api')
        end
      end
    end
  end
end
