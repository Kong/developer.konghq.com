# frozen_string_literal: true

require 'yaml'
require_relative '../monkey_patch'

module Jekyll
  class KonnectRolesTable < Liquid::Block # rubocop:disable Style/Documentation
    def initialize(tag_name, markup, tokens)
      super
      @name = markup.strip
    end

    def render(context) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      contents = super
      config = YAML.load(contents)
      drop = Drops::KonnectRolesTable.new(config)

      context.stack do
        context['heading_level'] = Jekyll::ClosestHeading.new(@page, @line_number, context).level
        context['config'] = drop
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% konnect_roles_table %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end

    def template
      if @page['output_format'] == 'markdown'
        File.read(File.expand_path('app/_includes/components/konnect_roles_table.md'))
      else
        File.read(File.expand_path('app/_includes/components/konnect_roles_table.html'))
      end
    end
  end
end

Liquid::Template.register_tag('konnect_roles_table', Jekyll::KonnectRolesTable)
