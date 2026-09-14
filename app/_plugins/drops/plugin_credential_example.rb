# frozen_string_literal: true

require 'securerandom'
require_relative 'plugin_credential_example/presenters/deck'
require_relative 'plugin_credential_example/presenters/admin-api'
require_relative 'plugin_credential_example/presenters/konnect-api'
require_relative 'plugin_credential_example/presenters/kic'
require_relative 'plugin_credential_example/presenters/terraform'

module Jekyll
  module Drops
    class PluginCredentialExample
      PRESENTERS = {
        'deck' => Presenters::Deck,
        'admin-api' => Presenters::AdminAPI,
        'konnect-api' => Presenters::KonnectAPI,
        'kic' => Presenters::KIC,
        'terraform' => Presenters::Terraform
      }.freeze

      REQUIRED_KEYS = [
        %w[consumer username],
        %w[credential endpoint],
        %w[credential deck_key],
        %w[credential data]
      ].freeze

      attr_reader :plugin_name

      def initialize(plugin_name:, example_formats:, definition:)
        @plugin_name = plugin_name
        @example_formats = example_formats
        @definition = definition
        validate!
      end

      def id
        @id ||= SecureRandom.hex(10)
      end

      def formats
        @formats ||= supported_formats & @example_formats
      end

      def consumer
        @consumer ||= @definition['consumer']
      end

      def credential
        @credential ||= @definition['credential']
      end

      def admin_api_path
        @admin_api_path ||= "/consumers/#{consumer['username']}/#{credential['endpoint']}"
      end

      def kic_credential_label
        @kic_credential_label ||= credential['endpoint']
      end

      def terraform_resource_name
        @terraform_resource_name ||= "konnect_gateway_#{credential['endpoint'].tr('-', '_')}"
      end

      def formatted_examples
        @formatted_examples ||= formats.map do |format|
          FormattedExample.new(format: format, presenter: PRESENTERS.fetch(format).new(credential_example: self))
        end
      end

      class FormattedExample < Liquid::Drop
        attr_reader :format, :presenter

        def initialize(format:, presenter:)
          @format = format
          @presenter = presenter
        end

        def template_file
          @presenter.template_file
        end
      end

      private

      def supported_formats
        @supported_formats ||= site.data['entity_examples']['config']['formats'].keys & PRESENTERS.keys
      end

      def site
        @site ||= Jekyll.sites.first
      end

      def validate!
        REQUIRED_KEYS.each do |path|
          value = @definition.dig(*path)
          raise ArgumentError, "Missing key `#{path.join('.')}` in credentials for #{@plugin_name}" if value.nil?
        end
      end
    end
  end
end
