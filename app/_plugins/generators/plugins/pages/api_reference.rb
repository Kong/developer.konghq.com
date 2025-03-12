# frozen_string_literal: true

require 'yaml'
require_relative './base'

module Jekyll
  module PluginPages
    module Pages
      class ApiReference < Base # rubocop:disable Style/Documentation
        def self.url(slug)
          "/plugins/#{slug}/api/"
        end

        def content
          ''
        end

        def data
          super
            .except('faqs')
            .merge('api_reference?' => true, 'toc' => false, 'no_version' => true)
            .merge('api_spec' => api_spec)
        end

        def layout
          'plugins/api_reference'
        end

        def api_spec
          @api_spec ||= YAML.load(File.read(file))
        end
      end
    end
  end
end
