# frozen_string_literal: true

require_relative './entity_example/utils/variable_replacer'

module Jekyll
  module Drops
    class EntityExamples < Liquid::Drop
      def initialize(config: nil, raw_body: nil, format:)
        @config = config
        @raw_body = raw_body
        @format = format
      end

      # --- deck ---

      def entities
        @entities ||= @config.fetch('entities')
      end

      def data
        @data ||= EntityExample::Utils::VariableReplacer::DeckData.run(
          data: requote_conditions(Jekyll::Utils::HashToYAML.new(entities).convert),
          variables: variables
        )
      end

      def deck_flags
        @deck_flags ||= @config.fetch('deck_flags', [])
      end

      # --- kongctl ---

      # The raw YAML body with !env / !lookup tags, minus the `variables:` and
      # `formats:` stanzas, with ${key} placeholders substituted and !env tags applied.
      def kongctl_data
        @kongctl_data ||= begin
          stripped = strip_metadata_keys(@raw_body)
          substituted = substitute_variables(stripped)
          EntityExample::Utils::VariableReplacer::KongctlData.apply_tags(substituted)
        end
      end

      # variables: { 'key' => { 'value' => '$VAR', 'description' => '...' } }
      def variables
        @variables ||= if @format == 'kongctl'
                         extract_variables_from_raw(@raw_body)
                       else
                         @config.fetch('variables', {})
                       end
      end

      # missing_variables for the placeholder list rendered by replace_variables.md
      def missing_variables
        @missing_variables ||= variables.filter_map do |_key, var|
          next unless var['description']

          placeholder = EntityExample::Utils::VariableReplacer::KongctlData.apply_tags(
            EntityExample::Utils::VariableReplacer::KongctlData.run(data: var['value'])
          )
          { 'placeholder' => placeholder, 'description' => var['description'] }
        end
      end

      def template
        @template ||= if @format == 'kongctl'
                        File.expand_path('app/_includes/components/entity_examples_kongctl.html')
                      else
                        File.expand_path('app/_includes/components/entity_examples.html')
                      end
      end

      private

      METADATA_KEYS = %w[variables formats].freeze

      # Remove `variables:` and `formats:` top-level stanzas from the raw body.
      # These are block metadata; the rest is verbatim kongctl YAML.
      def strip_metadata_keys(body)
        # Split on top-level keys (lines that start with a word char and a colon).
        # Rebuild, dropping any stanza whose key is in METADATA_KEYS.
        lines = body.lines
        result = []
        skip = false

        lines.each do |line|
          if (m = line.match(/\A([A-Za-z_][A-Za-z0-9_]*):/))
            skip = METADATA_KEYS.include?(m[1])
          end
          result << line unless skip
        end

        result.join.strip
      end

      # Parse only the `variables:` stanza from the raw body.
      # This stanza contains no YAML tags, so YAML.load is safe here.
      def extract_variables_from_raw(body)
        # Grab the variables stanza lines
        lines = body.lines
        in_variables = false
        stanza_lines = []

        lines.each do |line|
          if line.match(/\Avariables:/)
            in_variables = true
            stanza_lines << line
          elsif in_variables
            # Stop at the next top-level key
            break if line.match(/\A[A-Za-z_][A-Za-z0-9_]*:/)

            stanza_lines << line
          end
        end

        return {} if stanza_lines.empty?

        parsed = YAML.safe_load(stanza_lines.join)
        parsed&.fetch('variables', {}) || {}
      end

      # Replace ${key} placeholders in a raw YAML string using the variables hash,
      # then convert bare $VAR_NAME to the kongctl env sentinel so apply_tags
      # can convert them to !env VAR_NAME.
      def substitute_variables(str)
        return str if variables.empty?

        keys_pattern = variables.keys.map { |k| Regexp.escape(k.to_s) }.join('|')
        result = str.gsub(/\$\{(#{keys_pattern})\}/) do
          variables.dig(Regexp.last_match(1), 'value') || Regexp.last_match(0)
        end
        # Convert bare $UPPER_CASE_VAR to sentinel (mirrors KongctlData#transform_env_var)
        result.gsub(/(?<!\w)\$([A-Z][A-Z0-9_]*)(?!\w)/, '__kongctl_env_\1__')
      end

      def requote_conditions(yaml)
        yaml.gsub(/^(\s+condition:\s+)'((?:[^']|'')*)'/) do
          prefix = $1
          inner = $2.gsub("''", "'").gsub('\\', '\\\\').gsub('"', '\\"')
          "#{prefix}\"#{inner}\""
        end
      end
    end
  end
end
