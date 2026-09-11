# frozen_string_literal: true

require 'json'

module Jekyll
  module Drops
    class Quickstart < Liquid::Drop # rubocop:disable Style/Documentation
      def initialize(yaml:, product:) # rubocop:disable Lint/MissingSuper
        @yaml = yaml
        @product = product
      end

      def script_url
        "https://get.konghq.com/#{@product}"
      end

      def kafka_network_name
        "kafka_#{product_underscored}"
      end

      def gateway_id_var
        "#{product_underscored.upcase}_ID"
      end

      def control_plane_name
        "#{@product}-quickstart"
      end

      def env
        @env ||= @yaml['env'] || {}
      end

      def command
        flags = ['-k $KONNECT_TOKEN', "-N #{kafka_network_name}"] + env_flags

        return "curl -Ls #{script_url} | bash -s -- #{flags.join(' ')}" if env.empty?

        lines = ["curl -Ls #{script_url} | bash -s -- \\"]
        flags.each_with_index do |flag, index|
          continuation = index == flags.size - 1 ? '' : ' \\'
          lines << "  #{flag}#{continuation}"
        end
        lines.join("\n")
      end

      def section
        @yaml['section'] || 'step'
      end

      def data_validate
        return nil if section == 'none'

        JSON.dump({ name: 'quickstart', config: { env: env } })
      end

      private

      def product_underscored
        @product_underscored ||= @product.tr('-', '_')
      end

      def env_flags
        env.map { |key, value| %(-e "#{key}=#{value}") }
      end
    end
  end
end
