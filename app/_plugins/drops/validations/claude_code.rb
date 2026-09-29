# frozen_string_literal: true

require 'json'
require_relative './base'

module Jekyll
  module Drops
    module Validations
      class ClaudeCode < Base # rubocop:disable Style/Documentation
        def validate_yaml!
          raise ArgumentError, "Missing `prompt` in {% validation #{id} %}." unless @yaml.key?('prompt')
          raise ArgumentError, "Missing `model` in {% validation #{id} %}." unless @yaml.key?('model')
        end

        def data_validate
          JSON.dump({ name: id, config: config })
        end

        def config
          @config ||= configuration.merge('command' => command, 'base_command' => base_command)
        end

        def base_command
          @base_command ||= [
            configuration.fetch('command'),
            "--model \"#{@yaml.fetch('model')}\""
          ].join(' ')
        end

        def command
          @command ||= [
            *env_vars,
            configuration.fetch('command'),
            "--model \"#{@yaml.fetch('model')}\"",
            "-p \"#{@yaml.fetch('prompt')}\""
          ].join(' ')
        end

        private

        def env_vars
          [
            ('CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1' if self['disable_experimental_betas']),
            ("ANTHROPIC_BASE_URL=#{self['base_url']}" if self['base_url'])
          ].compact
        end
      end
    end
  end
end
