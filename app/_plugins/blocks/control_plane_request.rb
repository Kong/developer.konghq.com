# frozen_string_literal: true

require 'yaml'

module Jekyll
  class ControlPlaneRequest < Liquid::Block # rubocop:disable Style/Documentation
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

      # unless @page.fetch('products', []).include?('gateway')
      #   raise ArgumentError,
      #         'Unsupported product for {% control-plane-request %}'
      # end
      # unless @page.key?('works_on')
      #   raise ArgumentError,
      #         "Required metadata `works_on` for {% control-plane-request %} missing on #{@page['path']}"
      # end

      config = YAML.load(contents)
      drop = Drops::ControlPlaneRequest.new(yaml: config, format: @format)

      context.stack do
        context['config'] = drop
        Liquid::Template.parse(File.read(drop.template_file), { line_numbers: true }).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% control_plane_request %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end
  end
end

Liquid::Template.register_tag('control_plane_request', Jekyll::ControlPlaneRequest)
