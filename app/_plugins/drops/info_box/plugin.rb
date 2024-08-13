# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module InfoBox
      class Plugin < Base
        def topologies
          @topologies ||= @page['topologies']
        end

        def publisher
          @publisher ||= begin
            publisher = @site.data['plugin_publishers'].detect do |p|
              p['slug'] == @page['publisher']
            end

            publisher
          end
        end

        def plugin
          @plugin ||= @page
        end

        def protocols
          # XXX: hardcoded for now until we pull the schemas
          @protocols ||= ['grpc', 'grpcs', 'http', 'https']
        end

        def template_file
          @template_file ||= File.expand_path('app/_includes/components/info_box/plugin.html')
        end
      end
    end
  end
end
