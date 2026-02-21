# frozen_string_literal: true

require 'yaml'

module Jekyll
  class HttpRequest < Liquid::Block # rubocop:disable Style/Documentation
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
      drop = Drops::HttpRequest.new(yaml: config, format: @format)

      context.stack do
        context['config'] = drop
        Liquid::Template.parse(File.read(drop.template_file), { line_numbers: true }).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% http_request %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end
  end
end

Liquid::Template.register_tag('http_request', Jekyll::HttpRequest)
