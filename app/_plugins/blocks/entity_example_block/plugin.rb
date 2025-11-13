# frozen_string_literal: true

require_relative './base'
require_relative './plugin_target'

module Jekyll
  module EntityExampleBlock
    class Plugin < Base
      def target
        @target ||= PluginTarget.new(data: data)
      end

      def ordering
        @ordering ||= @example.dig('data', 'ordering')
      end

      def tags
        @tags ||= @example.dig('data', 'tags') || []
      end
    end
  end
end
