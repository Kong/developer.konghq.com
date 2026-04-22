# frozen_string_literal: true

module Jekyll
  module PromptPages
    class Generator
      PROMPTS_FOLDER = '_prompts'

      def self.run(site)
        new(site).run
      end

      attr_reader :site

      def initialize(site)
        @site = site
      end

      def run
        return if site.config.dig('skip', 'prompts')

        Dir.glob(File.join(site.source, "#{PROMPTS_FOLDER}/*.{yaml,yml}")).each do |file|
          slug = File.basename(file, File.extname(file))
          prompt = Jekyll::PromptPages::Prompt.new(file:, slug:)

          generate_overview_page(prompt)
        end
      end

      private

      def generate_overview_page(prompt)
        overview = Jekyll::PromptPages::Pages::Overview
                   .new(prompt:)
                   .to_jekyll_page

        site.data['prompts'] << overview
        site.pages << overview
      end
    end
  end
end
