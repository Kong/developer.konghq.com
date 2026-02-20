# frozen_string_literal: true

require_relative '../monkey_patch'

module Jekyll
  class RenderMeshPolicy < Liquid::Tag
    def initialize(tag_name, param, tokens)
      super

      @param = param.strip
    end

    def render(context)
      @context = context
      @site    = context.registers[:site]
      @page    = @context.environments.first['page']
      @config = @param.split('.').reduce(context) { |c, key| c[key] } || @param
      @policy_slug = @config.is_a?(Hash) ? @config['slug'] : @config

      policy = @site.data['mesh_policies'][@policy_slug]

      unless policy
        raise ArgumentError,
              "Error rendering {% policy %} on page: #{@page['path']}. The policy `#{@policy_slug}` doesn't exist."
      end

      return '' if policy.data['published'] == false

      context.stack do
        context['policy'] = policy
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/mesh_policy.html'))
    end
  end
end

Liquid::Template.register_tag('mesh_policy', Jekyll::RenderMeshPolicy)
