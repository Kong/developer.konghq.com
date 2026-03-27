# frozen_string_literal: true

require 'cgi'
require 'yaml'

module Jekyll
  module PromptPages
    class Prompt # rubocop:disable Style/Documentation
      attr_reader :slug, :file

      def initialize(file:, slug:)
        @file = file
        @slug = slug
      end

      def metadata
        @metadata ||= YAML.load_file(@file)
      end

      def title
        @title ||= metadata['title']
      end

      def prompt
        @prompt ||= metadata['prompt']
      end

      def description
        @description ||= metadata['description']
      end

      def products
        @products ||= metadata['products'] || []
      end

      def context
        @context ||= metadata['context'] || []
      end

      def url
        @url ||= "/prompts/#{@slug}/"
      end

      def kai_url
        @kai_url ||= "https://cloud.konghq.com/kai?prompt=#{CGI.escape(prompt)}"
      end
    end
  end
end
