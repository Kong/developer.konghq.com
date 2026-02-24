# frozen_string_literal: true

require 'yaml'
require_relative '../monkey_patch'

module Jekyll
  class FeatureTable < Liquid::Block
    def render(context)
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      contents = super

      config = YAML.load(contents)

      context.stack do
        context['heading_level'] = Jekyll::ClosestHeading.new(@page, @line_number, context).level
        context['include'] =
          { 'columns' => config['columns'], 'rows' => config['features'], 'item_title' => config['item_title'] }
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% feature_table %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end

    private

    def template
      if @page['output_format'] == 'markdown'
        File.read(File.expand_path('app/_includes/components/feature_table.md'))
      else
        File.read(File.expand_path('app/_includes/components/feature_table.html'))
      end
    end
  end
end

Liquid::Template.register_tag('feature_table', Jekyll::FeatureTable)
