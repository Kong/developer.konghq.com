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
        @yaml.fetch('section', 'step')
      end

      def test_attribute
        section == 'prereq' ? 'data-test-prereq' : 'data-test-step'
      end

      def data_validate
        JSON.dump({ name: 'quickstart', config: { env: env } })
      end
    end
  end
end
