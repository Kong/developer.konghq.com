# frozen_string_literal: true

require 'yaml'
require_relative '../monkey_patch'

module Jekyll
  class EntityExamples < Liquid::Block
    SUPPORTED_FORMATS = %w[deck kongctl].freeze

    def render(context) # rubocop:disable Metrics/MethodLength
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      contents = super

      formats = detect_formats(contents)

      unless formats
        raise ArgumentError,
              "Missing key `tools` in metadata, or `formats` in entity_examples block on page #{@page['path']}"
      end

      format = formats.first
      unless SUPPORTED_FORMATS.include?(format)
        raise ArgumentError,
              "entity_examples only supports #{SUPPORTED_FORMATS.join(', ')}, got `#{format}` on page #{@page['path']}"
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
    def detect_formats(contents)
      # Inline: `formats: [deck]` or `formats: [kongctl]`
      if (m = contents.match(/^formats:\s*\[([^\]]+)\]/))
        return m[1].split(',').map { |s| s.strip.delete("'\"") }
      end

      # Block sequence:
      #   formats:
      #     - kongctl
      if (m = contents.match(/^formats:\n((?:[ \t]*-[ \t]+\S+\n?)+)/))
        return m[1].scan(/\S+$/).map(&:strip)
      end

      # Fall back to page-level `tools:` frontmatter
      @page['tools']
    end

    def render_deck(context, contents)
      config = YAML.load(contents)
      config = config.merge('formats' => @page['tools']) unless config['formats']

      @page['kong_plugins'] ||= []
      kong_plugins = plugins(config)
      @page['kong_plugins'].concat(kong_plugins) if kong_plugins.any?

      entity_examples_drop = Drops::EntityExamples.new(config:, format: 'deck')
      render_drop(context, entity_examples_drop)
    end

    def render_kongctl(context, contents)
      entity_examples_drop = Drops::EntityExamples.new(raw_body: contents, format: 'kongctl')
      render_drop(context, entity_examples_drop)
    end

    def render_drop(context, entity_examples_drop)
      template = File.read(entity_examples_drop.template)
      context.stack do
        context['entity_examples'] = entity_examples_drop
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    end
  end
end

Liquid::Template.register_tag('entity_examples', Jekyll::EntityExamples)
