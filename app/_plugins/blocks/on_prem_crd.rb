# frozen_string_literal: true

require 'yaml'

module Jekyll
  class OnPremCrd < Liquid::Block # rubocop:disable Style/Documentation
    def initialize(tag_name, markup, tokens)
      super
      @name = markup.strip
    end

    def render(context) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      contents = super

      unless @page.fetch('works_on', []).include?('on-prem')
        raise ArgumentError,
              'Page does not contain works_on: on-prem, but uses {% on_prem_crd %}'
      end

      config = YAML.load(contents)
      config = add_defaults(config)

      should_create_namespace = config.delete('create_namespace')

      # Process YAML for the code block
      config = config.to_yaml.delete_prefix("---\n").chomp.gsub(/version: '(.*)'/, 'version: "\1"')

      context.stack do
        context['config'] = config
        context['should_create_namespace'] = should_create_namespace
        Liquid::Template.parse(File.read('app/_includes/on_prem_crd.html'), { line_numbers: true }).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% on_prem_crd %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end

    def add_defaults(config)
      defaults = {
        'kind' => '@TODO', # Needed to make sure kind is the first item in the YAML output
        'apiVersion' => 'gateway-operator.konghq.com/v2beta1',
        'metadata' => {
          'name' => '@TODO',
          'namespace' => 'kong'
        },
        'spec' => {}
      }

      defaults.deep_merge(config)
    end
  end
end

Liquid::Template.register_tag('on_prem_crd', Jekyll::OnPremCrd)
