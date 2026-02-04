# frozen_string_literal: true

require 'yaml'

module Jekyll
  class KonnectCrd < Liquid::Block # rubocop:disable Style/Documentation
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
              'Page does not contain works_on: konnect, but uses {% konnect_crd %}'
      end

      config = YAML.load(contents)
      config = add_defaults(config)

      should_create_namespace = config.delete('create_namespace')

      # Process YAML for the code block
      config = config.to_yaml.delete_prefix("---\n").chomp.gsub(/version: '(.*)'/, 'version: "\1"')

      context.stack do
        context['config'] = config
        context['should_create_namespace'] = should_create_namespace
        Liquid::Template.parse(File.read(template_file)).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% konnect_crd %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end

    def add_defaults(config)
      defaults = {
        'kind' => '@TODO', # Needed to make sure kind is the first item in the YAML output
        'apiVersion' => 'konnect.konghq.com/v1alpha1',
        'metadata' => {
          'name' => '@TODO',
          'namespace' => 'kong'
        },
        'spec' => {}
      }

      defaults.delete('spec') if config['kind'] == 'KongPlugin'

      defaults.deep_merge(config)
    end

    def template_file
      @template_file ||= if @page['output_format'] == 'markdown'
                           'app/_includes/konnect_crd.md'
                         else
                           'app/_includes/konnect_crd.html'
                         end
    end
  end
end

Liquid::Template.register_tag('konnect_crd', Jekyll::KonnectCrd)
