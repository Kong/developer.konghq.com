# frozen_string_literal: true

require_relative './releasable'

module Jekyll
  module ReleaseInfo
    class Tool
      include Releasable

      def initialize(site:, tool:, min_version:, max_version:)
        @site = site
        @tool = tool
        @min_version = min_version
        @max_version = max_version
      end

      def available_releases
        @available_releases ||= (@site.data.dig('tools', @tool, 'releases') || [])
                                .map { |r| Drops::Release.new(r) }
      end

      private

      def key
        @key ||= @tool
      end
    end
  end
end
