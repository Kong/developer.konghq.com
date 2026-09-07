# frozen_string_literal: true

require_relative '../policies/generator'
require_relative '../policies/generator_base'
require_relative '../release_info/major_resolver'

module Jekyll
  module MeshPolicyPages
    class Generator # rubocop:disable Style/Documentation
      include Policies::Generator
      include Policies::GeneratorBase

      VERSION_SEGMENT = /\Av(\d+)\z/

      def self.policies_folder
        '_mesh_policies'
      end

      def key
        @key ||= 'mesh_policies'
      end

      def skip?
        site.config.dig('skip', 'mesh_policy')
      end

      def skip_locally?
        @build_filter.excludes_prefix?('/mesh/')
      end

      def run
        return if skip_locally?

        seed_current_major_alias

        top_level_folder.each do |entry, slug|
          if VERSION_SEGMENT.match?(slug)
            generate_version_major(entry, slug)
          else
            generate_pages(policy_class.new(folder: entry, slug:))
          end
        end
      end

      def generate_version_major(version_folder, version_slug)
        major = VERSION_SEGMENT.match(version_slug)[1].to_i

        Dir.glob(File.join(version_folder, '*/')).each do |folder|
          slug = folder.chomp('/').split('/').last

          generate_pages(policy_class.new(folder:, slug:, policy_major: major))
        end
      end

      def generate_overview_page(policy)
        overview = overview_page_class
                   .new(policy:, file: File.join(policy.folder, 'index.md'))
                   .to_jekyll_page

        store_overview(policy, overview)

        site.pages << overview
      end

      private

      def seed_current_major_alias # rubocop:disable Metrics/AbcSize
        site.data[key][current_major] ||= {}
        site.data[key]['latest'] ||= site.data[key][current_major]
      end

      def current_major
        @current_major ||= ReleaseInfo::MajorResolver.new(
          site:, product: 'mesh', page_major_version: nil, min_version: nil, max_version: nil
        ).resolve
      end

      def top_level_folder
        Dir.glob(File.join(site.source, "#{self.class.policies_folder}/*/")).map do |entry|
          slug = entry.gsub("#{site.source}/#{self.class.policies_folder}/", '').chomp('/')
          [entry, slug]
        end
      end

      def store_overview(policy, overview)
        site.data[key][policy.policy_major] ||= {}
        site.data[key][policy.policy_major][policy.slug] = overview
      end
    end
  end
end
