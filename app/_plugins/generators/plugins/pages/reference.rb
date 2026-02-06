# frozen_string_literal: true

require 'yaml'

module Jekyll
  module PluginPages
    module Pages
      class Reference < Base # rubocop:disable Style/Documentation
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
          @markdown_content ||= File.read('app/_includes/plugins/reference.md')
        end

        def data
          super
            .except('faqs')
            .merge(metadata)
            .merge('reference?' => true, 'toc' => false)
            .merge(versions_info)
        end

        def metadata
          @metadata ||= YAML.load(File.read(file)) || {}
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
      end
    end
  end
end
