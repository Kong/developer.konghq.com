# frozen_string_literal: true

require 'yaml'

module Jekyll
  module Drops
    module ConfigExample
      module Base
        class EnvVariable < Liquid::Drop # rubocop:disable Style/Documentation
          def initialize(variable) # rubocop:disable Lint/MissingSuper
            @variable = variable
          end

          def value
            @value ||= @variable.fetch('value').gsub(/^\$/, '')
          end

          def description
            @description ||= @variable['description']
          end
        end

        attr_reader :file, :plugin

        def initialize(file:, plugin:)
          @file   = file
          @plugin = plugin
        end

        def slug
          @slug ||= File.basename(@file, File.extname(@file))
        end

        def config
          @config ||= example.fetch('config', {})
        end

        def description
          @description ||= example.fetch('description')
        end

        def extended_description
          @extended_description ||= example['extended_description']
        end

        def requirements
          @requirements ||= example.fetch('requirements', [])
        end

        def title
          @title ||= example.fetch('title')
        end

        def weight
          @weight ||= example.fetch('weight')
        end

        def min_version
          @min_version ||= example['min_version'] || @plugin.send(:min_version)
        end

        def id
          @id ||= SecureRandom.hex(10)
        end

        def group
          @group ||= @example['group']
        end

        def formats
          @formats ||= example.fetch('tools')
        end

        def variables
          @variables ||= example.fetch('variables', {}).map do |k, v|
            EnvVariable.new(v)
          end
        end

        def raw_variables
          @raw_variables ||= example.fetch('variables', {})
        end

        private

        def example
          @example ||= YAML.load(File.read(@file))
        end

        def site
          @site ||= Jekyll.sites.first
        end
      end
    end
  end
end
