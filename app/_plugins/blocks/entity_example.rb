# frozen_string_literal: true

require 'yaml'

module Jekyll
  class EntityExample < Liquid::Block
    def render(context) # rubocop:disable Metrics/MethodLength
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      contents = super

      entity_example = EntityExamples::Base.make_for(example: YAML.load(contents))
      entity_example_drop = entity_example.to_drop

      Liquid::Template
        .parse(File.read(entity_example_drop.template))
        .render(
          { 'site' => @site.config, 'page' => @page, 'include' => { 'entity_example' => entity_example_drop } },
          { registers: @context.registers, context: @context }
        )
    end
  end
end

Liquid::Template.register_tag('entity_example', Jekyll::EntityExample)
