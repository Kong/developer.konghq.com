# frozen_string_literal: true

require 'json'
require_relative './base'

module Jekyll
  module Drops
    module Validations
      class Qwen < Base # rubocop:disable Style/Documentation
        def validate_yaml!
          raise ArgumentError, "Missing `prompt` in {% validation #{id} %}." unless @yaml.key?('prompt')
          raise ArgumentError, "Missing `model` in {% validation #{id} %}." unless @yaml.key?('model')
          raise ArgumentError, "Missing `auth-type` in {% validation #{id} %}." unless @yaml.key?('auth-type')
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
            "--model \"#{@yaml.fetch('model')}\"",
            "--auth-type \"#{@yaml.fetch('auth-type')}\""
          ].join(' ')
        end

        def command
          @command ||= [
            configuration.fetch('command'),
            "--model \"#{@yaml.fetch('model')}\"",
            "--auth-type \"#{@yaml.fetch('auth-type')}\"",
            "--prompt \"#{@yaml.fetch('prompt')}\""
          ].join(' ')
        end
      end
    end
  end
end
