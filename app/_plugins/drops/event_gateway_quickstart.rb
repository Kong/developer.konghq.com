# frozen_string_literal: true

require 'json'
require_relative './concerns/test_section'

module Jekyll
  module Drops
    class EventGatewayQuickstart < Liquid::Drop # rubocop:disable Style/Documentation
      include Jekyll::Drops::Concerns::TestSection

      def initialize(yaml:) # rubocop:disable Lint/MissingSuper
        @yaml = yaml

        validate_section!
      end

      def env
        @env ||= @yaml['env'] || {}
      end

      def data_validate
        JSON.dump({ name: 'quickstart', config: { env: env } })
      end
    end
  end
end
