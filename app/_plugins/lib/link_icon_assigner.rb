# frozen_string_literal: true

require 'uri'

module Jekyll
  class LinkIconAssigner # rubocop:disable Style/Documentation
    include Jekyll::SiteAccessor

    ICON_MAP = {
      'video' => 'youtube',
      'learning-center' => 'graduation',
      'github' => 'github'
    }.freeze

    URL_ICON_MAP = {
      %r{^https://youtube} => 'youtube',
      %r{^https://konghq.com/blog/learning-center} => 'graduation',
      %r{^https://github} => 'github'
    }.freeze

    CONTENT_TYPE_ICON_MAP = {
      'how_to' => 'book',
      'plugin' => 'plug',
      'plugin_example' => 'plug'
    }

    def initialize(resource)
      @resource = resource
    end

    def process
      @resource['icon'] ||= "/assets/icons/#{determine_icon}.svg"
      @resource
    end

    private

    def determine_icon
      icon_for_type || icon_for_url || icon_for_content_type
    end

    def icon_for_type
      ICON_MAP[@resource['type']]
    end

    def icon_for_url
      return if @resource['url'].start_with?('/')

      URL_ICON_MAP.find { |pattern, _| @resource['url'] =~ pattern }&.last || 'service-document'
    end

    def icon_for_content_type
      return 'service-document' if ENV['KONG_PRODUCTS']

      url = URI.parse(@resource['url']).path
      final_url = resolve_final_path(url, site_redirects)

      page = site.pages.detect { |p| p.url == final_url }
      page ||= site.documents.detect { |d| d.url == final_url }

      raise ArgumentError, "Cannot determine icon for resource with URL #{@resource['url']}" unless page

      CONTENT_TYPE_ICON_MAP.fetch(page.data['content_type'], 'service-document')
    end

    def resolve_final_path(url, redirects)
      visited = Set.new

      while redirects.key?(url)
        return nil if visited.include?(url)

        visited.add(url)
        url = redirects[url]
      end

      url
    end
  end
end
