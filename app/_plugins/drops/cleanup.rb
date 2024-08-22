# frozen_string_literal: true

module Jekyll
  module Drops
    class Cleanup < Liquid::Drop
      def initialize(cleanup:, tools:)
        @cleanup = cleanup
        @tools   = tools
      end

      def any?
        @tools.any? || inline.any?
      end

      def inline
        @inline ||= @cleanup.fetch('inline', [])
      end
    end
  end
end