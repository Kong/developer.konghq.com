# frozen_string_literal: true

require 'json'

module Jekyll
  module Drops
    class EventGatewayQuickstart < Liquid::Drop # rubocop:disable Style/Documentation
      def initialize(yaml:) # rubocop:disable Lint/MissingSuper
        @yaml = yaml
      end

      def env
        @env ||= @yaml['env'] || {}
      end

      def section
        @yaml['section'] || 'step'
      end

      def data_validate
        return nil if section == 'none'

        JSON.dump({ name: 'quickstart', config: { env: env } })
      end
    end
  end
end
