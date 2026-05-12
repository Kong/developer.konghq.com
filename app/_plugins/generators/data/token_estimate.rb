# frozen_string_literal: true

require 'yaml'

module Jekyll
  module Data
    class TokenEstimate
      CHARS_PER_TOKEN = 4

      def self.estimate(text)
        return 0 if text.nil? || text.empty?

        (text.length / CHARS_PER_TOKEN.to_f).round
      end

      attr_reader :site, :page

      def initialize(site:, page:)
        @site = site
        @page = page
      end

      def process
        return if @page.url.start_with?('/assets/')
        return if @page.data['llm'] == false

        @page.data['tokens'] = self.class.estimate(estimable_text)
      end

      # Landing pages keep most of their copy in `page.data['rows']` rather than
      # `page.content`, so fall back to dumping the structured config when the
      # raw body is sparse. Same trick covers any other YAML-driven page type.
      def estimable_text
        body = @page.content.to_s
        return body if body.length > 200

        rows = @page.data['rows']
        return body if rows.nil?

        body + YAML.dump(rows)
      end
    end
  end
end
