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

      contents = super
      config = YAML.load(contents)
      drop = Drops::EnvVariables.new(yaml: config)

      context.stack do
        context['config'] = drop
        Liquid::Template.parse(File.read(drop.template_file)).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% env_variables %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end
  end
end

Liquid::Template.register_tag('env_variables', Jekyll::EnvVariables)
