# frozen_string_literal: true

require_relative './base'
require_relative '../../generators/mesh_policy/pages/base'

module Jekyll
  module Drops
    module PolicyConfigExample
      class Mesh < Base
        def url
          @url ||= if @plugin.unreleased?
                     "#{base_url}#{@plugin.slug}/examples/#{slug}/#{@plugin.min_release}"
                   else
                     "#{base_url}#{@plugin.slug}/examples/#{slug}/"
                   end
        end

        def yaml_config
          @yaml_config ||= Jekyll::Utils::HashToYAML.new(
            example.fetch('config', {})
          ).convert
        end

        def namespace
          @namespace ||= example['namespace']
        end

        def use_meshservice
          @use_meshservice ||= example['use_meshservice']
        end

        def tools
          @tools ||= example.fetch('tools', nil)
        end

        private

        def base_url
          Jekyll::MeshPolicyPages::Pages::Base.base_url(@plugin)
        end
      end
    end
  end
end
