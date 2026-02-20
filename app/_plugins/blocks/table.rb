# frozen_string_literal: true

require 'yaml'
require_relative '../monkey_patch'

module Jekyll
  class Table < Liquid::Block # rubocop:disable Style/Documentation
    def render(context) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      contents = super.strip

      config = YAML.load(contents)

      # Convert code errors to use 'id'
      config['rows'] = config['rows'].map do |row|
        if row['code']
          row['id'] = row['code'] unless row['id']
          row['code'] = "`#{row['code']}`"
        end
        row
      end

      context.stack do
        context['include'] =
          { 'columns' => config['columns'], 'rows' => config['rows'] }
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% table %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/table.html'))
    end
  end
end

Liquid::Template.register_tag('table', Jekyll::Table)
