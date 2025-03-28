# frozen_string_literal: true

require 'yaml'

module Jekyll
  class KonnectApiRequest < Liquid::Block # rubocop:disable Style/Documentation
    def initialize(tag_name, markup, tokens)
      super
      @name = markup.strip
    end

    def render(context) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      contents = super

      unless @page.fetch('works_on', []).include?('konnect')
        raise ArgumentError,
              'Page does not contain works_on: konnect, but uses {% konnect_api_request %}'
      end

      config = YAML.load(contents)
      drop = Drops::KonnectApiRequest.new(yaml: config)

      context.stack do
        context['config'] = drop
        Liquid::Template.parse(File.read(drop.template_file)).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% konnect_api_request %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end
  end
end

Liquid::Template.register_tag('konnect_api_request', Jekyll::KonnectApiRequest)
