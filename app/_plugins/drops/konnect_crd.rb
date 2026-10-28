# frozen_string_literal: true

require_relative './concerns/test_section'

module Jekyll
  module Drops
    class KonnectCrd < Liquid::Drop # rubocop:disable Style/Documentation
      include Jekyll::Drops::Concerns::TestSection

      def initialize(yaml:, format:) # rubocop:disable Lint/MissingSuper
        @yaml = yaml
        @format = format

        validate_section!
      end

      def create_namespace
        @yaml['create_namespace']
      end

      def crd_yaml
        @crd_yaml ||= @yaml.except('create_namespace', 'section', 'indent').to_yaml
                           .delete_prefix("---\n").chomp
                           .gsub(/version: '(.*)'/, 'version: "\1"')
      end

      def template_file
        if @format == 'markdown'
          'app/_includes/konnect_crd.md'
        else
          'app/_includes/konnect_crd.html'
        end
      end
    end
  end
end
