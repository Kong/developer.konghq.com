# frozen_string_literal: true

module Jekyll
  module MeshPolicyPages
    class Generator # rubocop:disable Style/Documentation
      POLICIES_FOLDER = '_mesh_policies'

      def self.run(site)
        new(site).run
      end

      attr_reader :site

      def initialize(site)
        @site = site
      end

      def run
        Dir.glob(File.join(site.source, "#{POLICIES_FOLDER}/*/")).each do |folder|
          slug = folder.gsub("#{site.source}/#{POLICIES_FOLDER}/", '').chomp('/')

          generate_pages(Jekyll::MeshPolicyPages::Policy.new(folder:, slug:))
        end
      end

      def generate_pages(policy)
        generate_overview_page(policy)
        generate_reference_page(policy)
        generate_example_pages(policy)
      end

      def generate_overview_page(policy)
        overview = Jekyll::MeshPolicyPages::Pages::Overview
                   .new(policy:, file: File.join(policy.folder, 'index.md'))
                   .to_jekyll_page

        site.data['mesh_policies'][policy.slug] = overview
        site.pages << overview
      end

      def generate_reference_page(policy)
        reference = Jekyll::MeshPolicyPages::Pages::Reference
                    .new(policy:, file: File.join(policy.folder, 'reference.md'))
                    .to_jekyll_page

        site.pages << reference
      end

      def generate_example_pages(policy)
        policy.example_files.each do |example_file|
          example = Jekyll::MeshPolicyPages::Pages::Example
                    .new(policy:, file: example_file)
                    .to_jekyll_page

          site.pages << example
        end
      end
    end
  end
end
