# frozen_string_literal: true

require 'yaml'

module Jekyll
  class EnvVariables < Liquid::Block # rubocop:disable Style/Documentation
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
      drop = Drops::Validations::Base.make_for(id: 'env-variables', yaml: config, format: @format)
      context.stack do
        context['config'] = drop
        context['heading_level'] = heading_level
        Liquid::Template.parse(File.read(drop.template_file), { line_numbers: true }).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% env_variables %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end

    def heading_level
      if @context['prereqs']
        4
      else
        Jekyll::ClosestHeading.new(@page, @line_number, @context).level
      end
    end
  end
end

Liquid::Template.register_tag('env_variables', Jekyll::EnvVariables)
