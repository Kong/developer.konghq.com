# frozen_string_literal: true

require 'yaml'
require 'json'

module Jekyll
  module PluginPages
    module Pages
      class Changelog < Base
        def self.url(plugin)
          if plugin.unreleased?
            "/plugins/#{plugin.slug}/changelog/#{plugin.min_release}/"
          else
            "/plugins/#{plugin.slug}/changelog/"
          end
        end

        def content
          @content ||= File.read('app/_includes/plugins/changelog.html')
        end

        def markdown_content
          @markdown_content ||= File.read('app/_includes/plugins/changelog.md')
        end

        def data
          super
            .except('faqs')
            .merge('content_type' => 'reference', 'changelog?' => true, 'changelog' => changelog)
        end

        def layout
          'plugins/with_aside'
        end

        def changelog
          @changelog ||= Drops::Plugins::Changelog.new(JSON.parse(File.read(file)))
        end
      end
    end
  end
end
