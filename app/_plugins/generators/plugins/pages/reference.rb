# frozen_string_literal: true

require 'yaml'

module Jekyll
  module PluginPages
    module Pages
      class Reference < Base
        def url
          @url ||= "/plugins/#{@plugin.slug}/reference/"
        end

        def content
          ''
        end

        def data
          super
            .merge(metadata)
            .merge('reference?' => true)
        end

        def metadata
          @metadata ||= YAML.load(File.read(file)) || {}
        end

        def layout
          'plugins/reference'
        end
      end
    end
  end
end
