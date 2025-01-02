# frozen_string_literal: true

require 'yaml'

module Jekyll
  class Validation < Liquid::Block # rubocop:disable Style/Documentation
    def render(context) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      contents = super

      config = YAML.load(contents)

      context.stack do
        context['config'] = Drops::Validations::RateLimitCheck.new(config)
        Liquid::Template.parse(
          File.read('app/_includes/how-tos/validations/rate-limit-check/index.html')
        ).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% validation %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end
  end
end

Liquid::Template.register_tag('validation', Jekyll::Validation)
