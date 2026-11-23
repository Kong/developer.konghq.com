# frozen_string_literal: true

module Jekyll
  module PolicyYaml
    # Parses the `{% policy_yaml key=value ... %}` markup and resolves any
    # dot-path values (e.g. `page.example.namespace`) against the Liquid context.
    class Params
      DEFAULTS = { 'raw' => false, 'apiVersion' => 'kuma.io/v1alpha1', 'use_meshservice' => false }.freeze
      RESOLVABLE_KEYS = %w[use_meshservice namespace tools].freeze

      def initialize(markup)
        @values = DEFAULTS.merge(parse(markup))
      end

      def [](key)
        @values[key]
      end

      def resolve!(context)
        RESOLVABLE_KEYS.each { |key| resolve_key!(key, context) }
        self
      end

      private

      def parse(markup)
        markup.strip.split(' ').each_with_object({}) do |item, values|
          key, value = item.split('=')
          values[key] = value unless value == ''
        end
      end

      def resolve_key!(key, context)
        value = @values[key]
        return unless value.is_a?(String)

        if value.include?('.')
          resolve_reference!(key, value, context)
        else
          resolve_literal!(key, value)
        end
      end

      # namespace literals (no dot) are kept as set by #parse
      def resolve_literal!(key, value)
        case key
        when 'tools' then @values[key] = value.split(',')
        when 'use_meshservice' then @values[key] = (value == 'true')
        end
      end

      def resolve_reference!(key, value, context)
        resolved = value.split('.').reduce(context) { |c, part| c[part] }
        @values[key] = key == 'tools' ? resolved : (resolved || false)
      end
    end
  end
end
