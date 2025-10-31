# frozen_string_literal: true

module Jekyll
  module Policies
    module Generator # rubocop:disable Style/Documentation
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods # rubocop:disable Style/Documentation
        def run(site)
          new(site).run
        end
      end

      attr_reader :site

      def initialize(site)
        @site = site
      end

      def run # rubocop:disable Metrics/AbcSize
        Dir.glob(File.join(site.source, "#{self.class.policies_folder}/*/")).each do |folder|
          slug = folder.gsub("#{site.source}/#{self.class.policies_folder}/", '').chomp('/')

          generate_pages(policy_class.new(folder:, slug:))
        end
      end

      def generate_pages(policy)
        generate_overview_page(policy)

        return if skip?

        generate_reference_page(policy)
        generate_example_pages(policy)
      end

      def generate_overview_page(policy)
        overview = overview_page_class
                   .new(policy:, file: File.join(policy.folder, 'index.md'))
                   .to_jekyll_page

        site.data[key][policy.slug] = overview
        site.pages << overview
      end

      def generate_reference_page(policy)
        reference = reference_page_class
                    .new(policy:, file: File.join(policy.folder, 'reference.md'))
                    .to_jekyll_page

        site.pages << reference
      end

      def generate_example_pages(policy)
        policy.example_files.each do |example_file|
          example = example_page_class
                    .new(policy:, file: example_file)
                    .to_jekyll_page

          site.pages << example
        end
      end

      private

      def namespace
        @namespace ||= self.class.name.deconstantize
      end
    end
  end
end
