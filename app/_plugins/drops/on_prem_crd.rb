# frozen_string_literal: true

module Jekyll
  module Drops
    class OnPremCrd < Liquid::Drop # rubocop:disable Style/Documentation
      def initialize(yaml:, format:) # rubocop:disable Lint/MissingSuper
        @yaml = yaml
        @format = format
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
        'app/_includes/on_prem_crd.html'
      end
    end
  end
end
