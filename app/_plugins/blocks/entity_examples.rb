# frozen_string_literal: true

require 'yaml'

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
        raise ArgumentError, "Missing key `tools` in metadata, or `formats` in entity_examples block on page #{@page['path']}"
      end
      unless config['formats'] == ['deck']
        raise ArgumentError, "entity_examples only supports deck, on page #{@page['path']}"
      end

      entity_examples_drop = Drops::EntityExamples.new(config:)

      template = File.read(entity_examples_drop.template)

      context.stack do
        context['entity_examples'] = entity_examples_drop
        context['example_index'] = example_index(@page, environment)
        Liquid::Template.parse(template).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
      On `#{@page['path']}`, the following {% entity_examples %} block contains a malformed yaml:
      #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
      #{e.message}
      STRING
      raise ArgumentError.new(message)
    end

    def example_index(page, environment)
      if page['content_type'] == 'how_to'
        environment[page['id']] ||= {}
        environment[page['id']]['examples'] ||= 0
        environment[page['id']]['examples'] += 1
      end
    end
  end
end

Liquid::Template.register_tag('entity_examples', Jekyll::EntityExamples)
