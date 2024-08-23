# frozen_string_literal: true

module Jekyll
  module EntityExampleBlock
    class PluginTarget < Base
      TARGETS = [
        'consumer',
        'consumer_group',
        'route',
        'service'
      ].freeze

      def initialize(data:)
        @data = data
      end

      def key
        @key ||= target.key || 'global'
      end

      def value
        @value ||= target.value
      end

      def target
        @target ||= begin
                      key, value = @data.slice(*TARGETS).first
                      OpenStruct.new(key:, value:)
                    end
      end
    end
  end
end
