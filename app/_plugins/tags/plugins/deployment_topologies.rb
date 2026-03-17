# frozen_string_literal: true

require_relative 'tabbed_tables'

module Jekyll
  module RenderPlugins
    class DeploymentTopologies < Liquid::Tag # rubocop:disable Style/Documentation
      def render(context)
        @context = context
        @page = context.environments.first['page']
        site = context.registers[:site]

        context.stack do
          context['type'] = table
          context['rows'] = rows(release(site))
          context['columns'] = columns(site)
          context['heading_level'] = Jekyll::ClosestHeading.new(@page, @line_number, context).level

          Liquid::Template.parse(template, { line_numbers: true }).render(context)
        end
      end

      def rows(release)
        Drops::Plugins::DeploymentTopologies.all(release:)
      end

      def table
        'deployment_topologies'
      end

      def columns(site)
        @columns ||= site.data.dig('plugins', 'tables', table, 'columns')
      end

      def template
        @template ||= File.read(File.expand_path('app/_includes/plugins/deployment_topologies.html'))
      end

      def release(site)
        @release ||= site.data['gateway_latest']
      end
    end
  end
end

Liquid::Template.register_tag('plugin_deployment_topologies', Jekyll::RenderPlugins::DeploymentTopologies)
