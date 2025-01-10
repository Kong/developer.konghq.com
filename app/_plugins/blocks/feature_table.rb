# frozen_string_literal: true

require 'yaml'

module Jekyll
  class FeatureTable < Liquid::Block
    def render(context)
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      contents = super

      config = YAML.load(contents)

      context.stack do
        context['include'] =
          { 'columns' => config['columns'], 'rows' => config['features'], 'item_title' => config['item_title'] }
        Liquid::Template.parse(template).render(context)
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
      @template ||= File.read(File.expand_path('app/_includes/components/feature_table.html'))
    end
  end
end

Liquid::Template.register_tag('feature_table', Jekyll::FeatureTable)
