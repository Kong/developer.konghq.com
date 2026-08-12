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
          @config ||= configuration.merge('command' => command)
        end

        def command
          @command ||= [
            configuration.fetch('command'),
            "--model \"#{@yaml.fetch('model')}\"",
            "-p \"#{@yaml.fetch('prompt')}\""
          ].join(' ')
        end
      end
    end
  end
end
