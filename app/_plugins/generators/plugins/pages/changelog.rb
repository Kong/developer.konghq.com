# frozen_string_literal: true

require 'yaml'

module Jekyll
  module PluginPages
    module Pages
      class Changelog < Base
        def self.url(slug)
          "/plugins/#{slug}/changelog/"
        end

        def content
          ''
        end

        def data
          super
            .except('faqs')
            .merge(metadata, 'changelog?' => true)
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
