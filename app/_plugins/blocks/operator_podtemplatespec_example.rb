# frozen_string_literal: true

require_relative '../monkey_patch'
require_relative '../component_templates'

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
        ComponentTemplates.fetch('operator_podtemplatespec_example', 'markdown').render(context)
      end
    end

  end
end

Liquid::Template.register_tag('operator_podtemplatespec_example', Jekyll::OperatorPodtemplatespecExample)
