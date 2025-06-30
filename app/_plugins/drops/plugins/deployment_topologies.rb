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
          @values ||= @plugin['plugin'].metadata['topologies']
        end
      end
    end
  end
end
