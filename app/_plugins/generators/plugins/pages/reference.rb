# frozen_string_literal: true

require 'yaml'
require_relative '../../../file_cache'

module Jekyll
  module PluginPages
    module Pages
      class Reference < Base
        def self.url(plugin)
          if plugin.unreleased?
            "/plugins/#{plugin.slug}/reference/#{plugin.min_release}/"
          else
            "/plugins/#{plugin.slug}/reference/"
          end
        end

        def content
          ''
        end

        def markdown_content
          @markdown_content ||= FileCache.read('app/_includes/plugins/reference.md')
        end

        def data
          super
            .except('faqs')
            .merge(metadata)
            .merge('reference?' => true, 'toc' => false)
            .merge(versions_info)
            .merge(aigw_onprem_data)
        end

        def metadata
          @metadata ||= YAML.load_file(file) || {}
        end

        def layout
          'plugins/reference'
        end

        def versions_info
          if @plugin.third_party?
            {}
          else
            { 'versioned' => true }
          end
        end

        def aigw_onprem_data
          return {} unless site.config.fetch('aigw_onprem_plugin_reference', []).include?(@plugin.slug)

          { 'aigw_onprem_url' => AIGatewayOnPremReference.url(@plugin) }
        end
      end
    end
  end
end
