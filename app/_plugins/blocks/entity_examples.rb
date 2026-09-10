# frozen_string_literal: true

require 'yaml'
require_relative '../monkey_patch'
require_relative '../component_templates'

module Jekyll
  class EntityExamples < Liquid::Block
    SUPPORTED_FORMATS = %w[deck kongctl].freeze

    def render(context) # rubocop:disable Metrics/MethodLength
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      contents = super

      formats, from_block = detect_formats(contents)

      unless formats
        raise ArgumentError,
              "Missing key `tools` in metadata, or `formats` in entity_examples block on page #{@page['path']}"
      end

      if from_block
        format = formats.find { |f| SUPPORTED_FORMATS.include?(f) }
        unless format
          raise ArgumentError,
                "entity_examples only supports #{SUPPORTED_FORMATS.join(', ')}, got `#{formats.join(', ')}` on page #{@page['path']}"
        end
      else
        supported = formats.select { |f| SUPPORTED_FORMATS.include?(f) }
        if supported.size != 1
          raise ArgumentError,
                "entity_examples block on page #{@page['path']} requires an explicit `formats:` key " \
                "because `tools` contains #{supported.empty? ? 'no supported formats' : 'multiple supported formats'}: #{formats.join(', ')}"
        end
        format = supported.first
      end

      if format == 'kongctl'
        render_kongctl(context, contents)
      else
        render_deck(context, contents)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% entity_examples %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError.new(message)
    end

    def plugins(config)
      return [] unless config.dig('entities', 'plugins')

      config['entities']['plugins'].map { |plugin| plugin['name'] }.compact
    end

    private

    # Extract the format list from the raw block body without YAML.load,
    # since kongctl blocks may contain !env / !lookup tags that Psych rejects.
    # Returns [formats, from_block] where from_block is true if formats came
    # from an explicit `formats:` key in the block body, false if from page tools.
    def detect_formats(contents)
      # Inline: `formats: [deck]` or `formats: [kongctl]`
      if (m = contents.match(/^formats:\s*\[([^\]]+)\]/))
        return [m[1].split(',').map { |s| s.strip.delete("'\"") }, true]
      end

      # Block sequence:
      #   formats:
      #     - kongctl
      if (m = contents.match(/^formats:\n((?:[ \t]*-[ \t]+\S+\n?)+)/))
        return [m[1].scan(/\S+$/).map(&:strip), true]
      end

      # Fall back to page-level `tools:` frontmatter
      [@page['tools'], false]
    end

    def render_deck(context, contents)
      config = YAML.load(contents)
      config = config.merge('formats' => @page['tools']) unless config['formats']

      @page['kong_plugins'] ||= []
      kong_plugins = plugins(config)
      @page['kong_plugins'].concat(kong_plugins) if kong_plugins.any?

      entity_examples_drop = Drops::EntityExamples.new(config:, format: 'deck')
      render_drop(context, entity_examples_drop, 'entity_examples')
    end

    def render_kongctl(context, contents)
      entity_examples_drop = Drops::EntityExamples.new(raw_body: contents, format: 'kongctl')
      render_drop(context, entity_examples_drop, 'entity_examples_kongctl')
    end

    def render_drop(context, entity_examples_drop, name)
      context.stack do
        context['entity_examples'] = entity_examples_drop
        ComponentTemplates.fetch(name, 'html').render(context)
      end
    end
  end
end

Liquid::Template.register_tag('entity_examples', Jekyll::EntityExamples)
