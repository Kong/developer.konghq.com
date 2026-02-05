# frozen_string_literal: true

require 'yaml'

module Jekyll
  class Validation < Liquid::Block # rubocop:disable Style/Documentation
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

      products = @page.fetch('products', [])

      unless %w[gateway kic ai-gateway operator event-gateway metering-and-billing].any? { |p| products.include?(p) }
        raise ArgumentError,
              "Unsupported product for {% validation #{@name} %}"
      end

      config = YAML.load(contents)
      drop = Drops::Validations::Base.make_for(yaml: config, id: @name, format: @format)

      output = context.stack do
        context['config'] = drop
        Liquid::Template.parse(File.read(drop.template_file)).render(context)
      end

      if config['indent']
        # If the config has an indent key, we need to indent the output
        # by that many spaces.
        indent = ' ' * config['indent'].to_i
        output = output.lines.map { |line| "#{indent}#{line}" }.join
      end

      output
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
