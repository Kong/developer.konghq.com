# frozen_string_literal: true

module Jekyll
  module Drops
    class APISpecLink < Liquid::Drop
      def initialize(api_spec:, site:)
        @api_spec = api_spec
        @site = site
      end

      def insomnia_link
        @insomnia_link ||= Drops::OAS::InsomniaLink.new(
          label: @api_spec.data['title'],
          version: @api_spec.data['version'],
          page_relative_path: @api_spec.relative_path,
          site: @site
        )
      end

      def url
        @url ||= @api_spec.url
      end

      def text
        @text ||= @api_spec.data['title']
      end
    end
  end
end
