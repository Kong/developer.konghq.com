# frozen_string_literal: true

require 'yaml'
require_relative '../../lib/site_accessor'

module Jekyll
  module PromptPages
    class Prompt
      include Jekyll::SiteAccessor

      attr_reader :file, :slug

      def initialize(file:, slug:)
        @file = file
        @slug = slug
      end

      def metadata
        @metadata ||= YAML.load_file(@file)
      end

      def title
        @title ||= metadata.fetch('title')
      end

      def description
        @description ||= metadata.fetch('description')
      end

      def extended_description
        @extended_description ||= metadata.fetch('extended_description', description)
      end

      def products
        @products ||= metadata.fetch('products', [])
      end

      def prompts
        @prompts ||= metadata.fetch('prompts', [])
      end
    end
  end
end
