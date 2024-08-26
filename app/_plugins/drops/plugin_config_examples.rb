# frozen_string_literal: true

module Jekyll
  module Drops
    class PluginConfigExamples < Liquid::Drop
      def initialize(page:, site:)
        @page = page
        @site = site
      end

      def targets
        @targets ||= @page.fetch('targets', [])
      end

      def formats
        @formats ||= @page.fetch('tools', [])
      end

      def examples
        @examples ||= @page.fetch('examples', [])
      end
    end
  end
end
