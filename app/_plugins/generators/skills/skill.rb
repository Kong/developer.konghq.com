# frozen_string_literal: true

module Jekyll
  module SkillPages
    class Skill
      attr_reader :site, :folder, :slug, :plugin

      def initialize(site:, folder:, slug:, plugin: nil)
        @site = site
        @folder = folder
        @slug = slug
        @plugin = plugin
      end

      def name
        @name ||= metadata.fetch('name', slug)
      end

      def description
        @description ||= metadata.fetch('description', '')
      end

      def version
        @version ||= metadata.dig('metadata', 'version') || plugin&.version
      end

      def author
        @author ||= metadata.dig('metadata', 'author') || metadata.dig('metadata', 'authors')
      end

      def license
        @license ||= metadata.fetch('license', nil)
      end

      def products
        @products ||= Array(metadata.dig('metadata', 'product'))
      end

      def category
        @category ||= metadata.dig('metadata', 'category')
      end

      def tags
        @tags ||= Array(metadata.dig('metadata', 'tags'))
      end

      def license_file?
        return false unless license

        File.exist?(File.join(@folder, license))
      end

      def allowed_tools
        @allowed_tools ||= metadata.fetch('allowed-tools', nil)
      end

      def scripts?
        Dir.exist?(File.join(@folder, 'scripts'))
      end

      def references?
        Dir.exist?(File.join(@folder, 'references'))
      end

      def assets?
        Dir.exist?(File.join(@folder, 'assets'))
      end

      def all_files
        @all_files ||= Dir.glob(File.join(@folder, '**', '*'))
                          .select { |file| File.file?(file) }
                          .map { |file| file.sub(@folder, '') }
                          .sort
      end

      def raw_content
        @raw_content ||= File.read(File.join(@folder, 'SKILL.md'))
      end

      def content
        @content ||= parser.content
      end

      def processed_content
        @processed_content ||= begin
          rewritten = Jekyll::SkillPages.rewrite_relative_links(
            content,
            site:,
            source_relative_path: File.join(source_path, 'SKILL.md')
          )
          Jekyll::SkillPages.demote_headings(rewritten)
        end
      end

      def metadata
        @metadata ||= parser.frontmatter
      end

      def source_path
        @source_path ||= if plugin
                           File.join('plugins', plugin.slug, 'skills', slug)
                         else
                           File.join('skills', slug)
                         end
      end

      def source_url
        @source_url ||= Jekyll::SkillPages.repo_tree_url(site, source_path)
      end

      def plugin_slug
        plugin&.slug
      end

      def plugin_name
        plugin&.name
      end

      def plugin_path
        plugin&.source_path
      end

      def plugin_source_url
        plugin&.source_url
      end

      def license_url
        return unless license_file?

        Jekyll::SkillPages.repo_blob_url(site, File.join(source_path, license))
      end

      def scripts_url
        Jekyll::SkillPages.repo_tree_url(site, File.join(source_path, 'scripts')) if scripts?
      end

      def references_url
        Jekyll::SkillPages.repo_tree_url(site, File.join(source_path, 'references')) if references?
      end

      def assets_url
        Jekyll::SkillPages.repo_tree_url(site, File.join(source_path, 'assets')) if assets?
      end

      private

      def parser
        @parser ||= Jekyll::Utils::MarkdownParser.new(raw_content)
      end
    end
  end
end
