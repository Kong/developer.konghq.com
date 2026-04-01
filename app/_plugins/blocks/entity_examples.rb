# frozen_string_literal: true

require 'yaml'
require_relative '../monkey_patch'

module Jekyll
  class EntityExamples < Liquid::Block
    def render(context) # rubocop:disable Metrics/MethodLength
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']
      environment = context.environments.first

      contents = super

      config = YAML.load(contents)
      config = config.merge('formats' => @page['tools']) unless config['formats']

      unless config['formats']
        raise ArgumentError,
              "Missing key `tools` in metadata, or `formats` in entity_examples block on page #{@page['path']}"
      end
      unless config['formats'] == ['deck']
        raise ArgumentError, "entity_examples only supports deck, on page #{@page['path']}"
      end

      @page['kong_plugins'] ||= []
      kong_plugins = plugins(config)
      @page['kong_plugins'].concat(kong_plugins) if kong_plugins.any?

      entity_examples_drop = Drops::EntityExamples.new(config:)

      template = File.read(entity_examples_drop.template)

      context.stack do
        context['entity_examples'] = entity_examples_drop
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
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
  end
end

Liquid::Template.register_tag('entity_examples', Jekyll::EntityExamples)
