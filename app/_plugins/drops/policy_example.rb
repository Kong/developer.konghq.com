# frozen_string_literal: true

require 'yaml'

module Jekyll
  module Drops
    class PolicyExample < Liquid::Drop # rubocop:disable Style/Documentation
      attr_reader :file

      def initialize(file:, policy:) # rubocop:disable Lint/MissingSuper
        @file   = file
        @policy = policy
      end

      def slug
        @slug ||= File.basename(@file, File.extname(@file))
      end

      def config
        @config ||= Jekyll::Utils::HashToYAML.new(
          example.fetch('config', {})
        ).convert
      end

      def description
        @description ||= example.fetch('description')
      end

      def extended_description
        @extended_description ||= example['extended_description']
      end

      def requirements
        @requirements ||= example.fetch('requirements', [])
      end

      def title
        @title ||= example.fetch('title')
      end

      def weight
        @weight ||= example.fetch('weight')
      end

      def url
        @url ||= if @policy.unreleased?
                   "/mesh/policies/#{@policy.slug}/examples/#{slug}/#{@policy.min_release}"
                 else
                   "/mesh/policies/#{@policy.slug}/examples/#{slug}/"
                 end
      end

      def id
        @id ||= SecureRandom.hex(10)
      end

      def namespace
        @namespace ||= example['namespace']
      end

      def use_meshservice
        @use_meshservice ||= example['use_meshservice']
      end

      private

      def example
        @example ||= YAML.load(File.read(@file))
      end

      def site
        @site ||= Jekyll.sites.first
      end
    end
  end
end
