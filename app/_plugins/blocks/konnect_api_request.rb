# frozen_string_literal: true

require 'yaml'
require_relative '../monkey_patch'

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
      @format = @page['output_format'] || 'html'

      contents = super

      unless @page.fetch('works_on', []).any? { |w| %w[konnect konnect-platform].include?(w) }
        raise ArgumentError,
              'Page does not contain works_on: konnect or konnect-platform, but uses {% konnect_api_request %}'
      end

      config = YAML.load(contents)
      drop = Drops::KonnectApiRequest.new(yaml: config, format: @format)

      output = context.stack do
        context['config'] = drop
        Liquid::Template.parse(File.read(drop.template_file), { line_numbers: true }).render(context)
      end

      if drop.config['indent']
        # Indent the output if specified in the example
        indent = ' ' * drop.config['indent'].to_i
        output = output.split("\n").map { |line| "#{indent}#{line}" }

        # Trim indent from ending line in code blocks
        output.each do |line|
          if line.start_with?("#{indent}</code>")
            line.sub!(/^#{indent}/, '') # Remove the indent from the line
          end
        end

        output = output.join("\n")
      end

      output
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
