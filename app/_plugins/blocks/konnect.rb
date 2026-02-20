# frozen_string_literal: true

require 'yaml'

module Jekyll
  class Konnect < Liquid::Block # rubocop:disable Style/Documentation
    def initialize(tag_name, markup, tokens)
      super
      @name = markup.strip
    end

    def render(context) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']
      @format = @page['output_format'] || 'html'

      contents = super

      config = YAML.load(contents)
      context.stack do
        context['config'] = config
        context['heading_level'] = Jekyll::ClosestHeading.new(@page, @line_number, context).level
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% konnect %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING

      raise ArgumentError, message
    end

    def template
      if @page['output_format'] == 'markdown'
        File.read(File.join(@site.source, '_includes/components/konnect.md'))
      else
        File.read(File.join(@site.source, '_includes/components/konnect.html'))
      end
    end
  end
end

Liquid::Template.register_tag('konnect', Jekyll::Konnect)
