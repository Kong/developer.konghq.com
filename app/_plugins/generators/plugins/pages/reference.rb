# frozen_string_literal: true

require 'yaml'

module Jekyll
  module PluginPages
    module Pages
      class Reference < Base
        def self.url(slug)
          "/plugins/#{slug}/reference/"
        end

        def content
          ''
        end

        def data
          super
            .except('faqs')
            .merge(metadata)
            .merge('reference?' => true, 'toc' => false)
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
