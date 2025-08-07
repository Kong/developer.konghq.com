# frozen_string_literal: true

module Jekyll
  module Serializers
    module Plugins
      class Example # rubocop:disable Style/Documentation
        def initialize(example)
          @example = example
        end

        def to_json(*_args)
          {
            'slug' => @example.slug,
            'config' => config,
            'env' => env,
            'required_fields' => required_fields
          }
        end

        private

        def env
          @example.variables.each_with_object({}) do |var, h|
            h[var.value] = var.description
          end
        end

        def config
          Drops::EntityExample::Utils::VariableReplacer::Data.run(
            data: @example.config,
            variables: @example.raw_variables
          )
        end

        def required_fields
          @example.plugin.schema.required_fields.map { |f| "config.#{f}" }
        end
      end
    end
  end
end
