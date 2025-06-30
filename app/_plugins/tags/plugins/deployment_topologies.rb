# frozen_string_literal: true

require_relative 'tabbed_tables'

module Jekyll
  module RenderPlugins
    class DeploymentTopologies < Liquid::Tag # rubocop:disable Style/Documentation
      include TabbedTables

      def rows(release)
        Drops::Plugins::DeploymentTopologies.all(release:)
      end

      def table
        'deployment_topologies'
      end
    end
  end
end

Liquid::Template.register_tag('plugin_deployment_topologies', Jekyll::RenderPlugins::DeploymentTopologies)
