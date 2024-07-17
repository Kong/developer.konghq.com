# frozen_string_literal: true

require 'yaml'

module Jekyll
  class EntityExample < Liquid::Block
    def render(context) # rubocop:disable Metrics/MethodLength
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      contents = super

      # Extract the indentation of the block tag
      tag_indentation = contents.match(/^\s*/)[0]

      entity_example = EntityExamples::Base.make_for(example: YAML.load(contents))
      entity_example_drop = entity_example.to_drop

      template = File.read(entity_example_drop.template)
      indented_template = preserve_indentation(template, tag_indentation)

      rendered_content = Liquid::Template
        .parse(indented_template)
        .render(
          { 'site' => @site.config, 'page' => @page, 'include' => { 'entity_example' => entity_example_drop } },
          { registers: @context.registers, context: @context }
        )
    rescue Psych::SyntaxError => e
      message = <<~STRING
      On `#{@page['path']}`, the following {% entity_example %} block contains a malformed yaml:
      #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
      #{e.message}
      STRING
      raise ArgumentError.new(message)
    end

    def preserve_indentation(template, indentation)
      template.lines.map { |line| "#{indentation}#{line}" }.join("\n")
    end
  end
end

Liquid::Template.register_tag('entity_example', Jekyll::EntityExample)
