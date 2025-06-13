# frozen_string_literal: true

require 'yaml'

module Jekyll
  class TrafficGenerator < Liquid::Block # rubocop:disable Style/Documentation
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
      drop = Drops::TrafficGenerator.new(yaml: config)

      output = context.stack do
        context['config'] = drop
        Liquid::Template.parse(File.read(drop.template_file)).render(context)
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
        On `#{@page['path']}`, the following {% traffic_generator %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end
  end
end

Liquid::Template.register_tag('traffic_generator', Jekyll::TrafficGenerator)
