# frozen_string_literal: true

require 'yaml'
require_relative './attributes'

module Jekyll
  class TutorialStep < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super

      @attributes = Blocks::Attributes.parse(markup)
      # raise error if it doesn't have a title
    end

    def render(context) # rubocop:disable Metrics/MethodLength
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      @title = @attributes['title']

      contents = super

      Liquid::Template
        .parse(File.read('app/_includes/components/tutorial_step.html'))
        .render(
          { 'site' => @site.config, 'page' => @page, 'include' => { 'content' => contents, 'title' => @title } },
          { registers: @context.registers, context: @context }
        )
    end
  end
end

Liquid::Template.register_tag('step', Jekyll::TutorialStep)
