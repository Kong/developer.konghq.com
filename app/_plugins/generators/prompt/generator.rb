# frozen_string_literal: true

require 'set'
require_relative 'prompt'
require_relative 'pages/page'
require_relative '../custom_jekyll_page'
require_relative '../../lib/site_accessor'

module Jekyll
  module PromptPages
    class Generator # rubocop:disable Style/Documentation
      include Jekyll::SiteAccessor

      def self.run(site)
        new(site).run
      end

      def initialize(site)
        @site = site
      end

      def run
        all_products = Set.new
        all_contexts = Set.new

        Dir.glob(File.join(@site.source, '_prompts', '*.yml')).sort.each do |file|
          slug = File.basename(file, '.yml')
          prompt = Prompt.new(file: file, slug: slug)
          jekyll_page = Pages::Page.new(prompt: prompt).to_jekyll_page
          @site.data['prompts'] << jekyll_page
          @site.pages << jekyll_page

          prompt.products.each { |p| all_products << p }
          prompt.context.each { |c| all_contexts << c }
        end

        @site.data['prompt_filters'] = {
          'products' => all_products.to_a.sort,
          'contexts' => all_contexts.to_a.sort
        }
      end
    end
  end
end
