# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module PolicyConfigExample
      class Mesh < Base
        def yaml_config
          @yaml_config ||= Jekyll::Utils::HashToYAML.new(
            example.fetch('config', {})
          ).convert
        end

        def namespace
          @namespace ||= example['namespace']
        end

        def use_meshservice
          @use_meshservice ||= example['use_meshservice']
        end
      end
    end
  end
end
