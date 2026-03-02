# frozen_string_literal: true

require_relative '../monkey_patch'

module Jekyll
  class OperatorPodtemplatespecExample < Liquid::Block
    def render(context)
      spec = super

      begin
        config = YAML.safe_load(spec)
      rescue Psych::SyntaxError => e
        raise "Unable to parse config in operator_podtemplatespec_example: \n#{spec}\n\n#{e}"
      end

      return '' unless config['dataplane']

      context.stack do
        context['kubectl_apply'] = config['kubectl_apply']
        context['spec'] = Jekyll::Utils::HashToYAML.new(config['dataplane']).convert(indent_level: 0)
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/operator_podtemplatespec_example.md'))
    end
  end
end

Liquid::Template.register_tag('operator_podtemplatespec_example', Jekyll::OperatorPodtemplatespecExample)
