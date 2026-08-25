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
          @config ||= configuration.merge('command' => command, 'base_command' => base_command)
        end

        def base_command
          @base_command ||= to_multiline([configuration.fetch('command'), *config_flags])
        end

        def command
          parts = [
            configuration.fetch('command'),
            "exec \"#{@yaml.fetch('prompt')}\"",
            *config_flags,
            '--skip-git-repo-check'
          ]
          @command ||= to_multiline(parts)
        end

        private

        # Renders as `line1 \\\n  line2 \\\n  line3`, matching the multi-line `--config`
        # examples shown elsewhere in the docs; `bash -c` treats it identically to one line.
        def to_multiline(parts)
          parts.join(" \\\n  ")
        end

        # Codex CLI has no env-var override for a custom upstream, so a named
        # `model_provider` must be declared via repeated `--config` flags instead.
        def config_flags
          provider = @yaml.fetch('model_provider')

          [
            "--config 'model=\"#{@yaml.fetch('model')}\"'",
            "--config 'model_provider=\"#{provider}\"'",
            "--config 'model_providers.#{provider}.name=\"#{@yaml.fetch('model_provider_name')}\"'",
            "--config 'model_providers.#{provider}.base_url=\"#{@yaml.fetch('model_provider_base_url')}\"'",
            "--config 'model_providers.#{provider}.env_key=\"#{@yaml.fetch('model_provider_env_key')}\"'",
            "--config 'model_providers.#{provider}.wire_api=\"#{@yaml.fetch('model_provider_wire_api')}\"'"
          ]
        end
      end
    end
  end
end
