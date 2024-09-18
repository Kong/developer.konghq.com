# frozen_string_literal: true

module Jekyll
  class LinkIconAssigner
    ICON_MAP = {
      'video'           => 'youtube',
      'learning-center' => 'graduation',
      'github'          => 'github'
    }.freeze

    URL_ICON_MAP = {
      /^https:\/\/youtube/ => 'youtube',
      /^https:\/\/konghq.com\/blog\/learning-center/ => 'graduation',
      /^https:\/\/github/ => 'github'
    }.freeze

    def initialize(resource)
      @resource = resource
    end

    def process
      @resource['icon'] = "/assets/icons/#{determine_icon}.svg"
      @resource
    end

    private

    def determine_icon
      icon_for_type || icon_for_url || 'book'
    end

    def icon_for_type
      ICON_MAP[@resource['type']]
    end

    def icon_for_url
      URL_ICON_MAP.find { |pattern, _| @resource['url'] =~ pattern }&.last
    end
  end
end