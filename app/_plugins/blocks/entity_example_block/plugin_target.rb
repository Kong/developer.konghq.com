# frozen_string_literal: true

require 'ostruct'

module Jekyll
  module EntityExampleBlock
    class PluginTarget < Base
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
                      key, value = @data.slice(*targets).first
                      OpenStruct.new(key:, value:)
                    end
      end

      private

      def targets
        @targets ||= site.data['entity_examples']['config']['targets'].keys
      end

      def site
        @site ||= Jekyll.sites.first
      end
    end
  end
end
