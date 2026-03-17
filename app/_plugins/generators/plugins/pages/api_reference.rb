# frozen_string_literal: true

require 'yaml'
require_relative './base'

module Jekyll
  module PluginPages
    module Pages
      class ApiReference < Base # rubocop:disable Style/Documentation
        def self.url(plugin)
          if plugin.unreleased?
            "/plugins/#{plugin.slug}/api/#{plugin.min_release}/"
          else
            "/plugins/#{plugin.slug}/api/"
          end
        end

        def content
          ''
        end

        def markdown_content
          @markdown_content ||= File.read('app/_includes/plugins/api_reference.md')
        end

        def data
          super
            .except('faqs')
            .merge('api_reference?' => true, 'toc' => false)
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
