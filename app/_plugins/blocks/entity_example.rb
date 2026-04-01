# frozen_string_literal: true

require 'yaml'
require_relative '../monkey_patch'

module Jekyll
  class EntityExample < Liquid::Block
    def render(context) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      contents = super

      example = YAML.load(contents)
      example = example.merge('formats' => formats(@page, @site)) unless example['formats']

      unless example['formats']
        raise ArgumentError,
              "Missing key `tools` in metadata, or `formats` in entity_example block on page #{@page['path']}"
      end

      entity_example = EntityExampleBlock::Base.make_for(example: example, product: product(@page))
      entity_example_drop = entity_example.to_drop

      template = File.read(entity_example_drop.template)

      output = context.stack do
        context['heading_level'] = Jekyll::ClosestHeading.new(@page, @line_number, context).level
        context['entity_example'] = entity_example_drop
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end

      if example['indent']
        # Indent the output if specified in the example
        indent = ' ' * example['indent'].to_i
        output = output.split("\n").map { |line| "#{indent}#{line}" }

        # Trim indent from ending line in code blocks
        output.each do |line|
          if line.start_with?("#{indent}</code>")
            line.sub!(/^#{indent}/, '') # Remove the indent from the line
          end
        end

        output = output.join("\n")
      end

      output
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% entity_example %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end

    def formats(page, site)
      return page['tools'] unless page['layout'] == 'gateway_entity'
      return page['tools'].dup << 'ui' if page['products']&.include?('event-gateway')

      supported_entities = site.data.dig('entity_examples', 'config', 'formats', 'ui', 'entities') || []
      return page['tools'] unless supported_entities.include?(page['entities'].first)

      page['tools'].dup << 'ui'
    end

    def product(page)
      products = page['products'] || []
      products.include?('gateway') ? 'gateway' : products.first || 'gateway'
    end
  end
end

Liquid::Template.register_tag('entity_example', Jekyll::EntityExample)
