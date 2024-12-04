# frozen_string_literal: true

require 'yaml'

module Jekyll
  module PluginPages
    module Pages
      class Changelog < Base
        def url
          @url ||= "/plugins/#{@plugin.slug}/changelog/"
        end

        def content
          ''
        end

        def data
          super.merge(metadata, 'changelog?' => true)
        end

        def metadata
          @metadata ||= YAML.load(File.read(file)) || {}
        end

        def layout
          'plugins/base'
        end
      end
    end
  end
end
