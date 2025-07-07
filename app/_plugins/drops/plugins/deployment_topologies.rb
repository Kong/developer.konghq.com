# frozen_string_literal: true

require 'json'
require_relative './tabular'
require_relative '../../lib/site_accessor'

module Jekyll
  module Drops
    module Plugins
      class DeploymentTopologies < Liquid::Drop
        include Tabular

        def columns
          @columns ||= site.data.dig('plugins', 'tables', 'deployment_topologies', 'columns').map do |c|
            c.fetch('key')
          end
        end

        def values
          @values ||= begin
            values = topologies
            values['notes'] = plugin_metadata['notes']
            values
          end
        end

        private

        def topologies
          @topologies ||= {
            'on_prem' => [],
            'konnect_deployments' => []
          }.merge(plugin_metadata['topologies'])
        end

        def plugin_metadata
          @plugin_metadata ||= @plugin['plugin'].metadata
        end
      end
    end
  end
end
