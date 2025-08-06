# frozen_string_literal: true

require_relative '../../../lib/site_accessor'

module Jekyll
  module PluginPages
    module Endpoints
      class Examples # rubocop:disable Style/Documentation
        include Jekyll::SiteAccessor

        def initialize(plugin)
          @plugin = plugin
        end

        def to_jekyll_page
          return if @plugin.examples.select(&:show_in_api?).empty?

          build_page
        end

        def data
          {
            'layout' => 'plugins/api',
            'plugin' => Serializers::Plugin.new(@plugin).to_json
          }
        end

        private

        def build_page
          PageWithoutAFile.new(site, site.source, '_api/plugins', "#{@plugin.slug}.json").tap do |page|
            page.content = ''
            page.data = data
          end
        end
      end
    end
  end
end
