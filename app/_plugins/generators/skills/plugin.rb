# frozen_string_literal: true

require 'json'

module Jekyll
  module SkillPages
    class Plugin
      attr_reader :site, :folder, :slug

      def initialize(site:, folder:, slug:)
        @site = site
        @folder = folder
        @slug = slug
      end

      def name
        @name ||= manifest['name'] || slug
      end

      def description
        @description ||= manifest['description']
      end

      def version
        @version ||= manifest['version']
      end

      def declared_skills
        @declared_skills ||= Array(manifest['skills']).filter_map do |path|
          next if path.nil? || path.empty?

          cleaned = path.sub(%r{\A\./}, '')
          parts = cleaned.split('/')
          next parts.last if parts.include?('skills')

          File.basename(cleaned)
        end.uniq
      end

      def source_path
        @source_path ||= File.join('plugins', slug)
      end

      def source_url
        @source_url ||= Jekyll::SkillPages.repo_tree_url(site, source_path)
      end

      def mcp_path
        @mcp_path ||= begin
          raw_path = manifest['mcpServers']
          if raw_path.nil? || raw_path.empty?
            nil
          else
            Jekyll::SkillPages.normalize_repo_path(source_path, raw_path)
          end
        end
      end

      def mcp_url
        return if mcp_path.nil?

        Jekyll::SkillPages.repo_blob_url(site, mcp_path)
      end

      def primary_install_command
        install_commands[1] || install_commands.first
      end

      def install_commands
        return [] unless Jekyll::SkillPages.marketplace_manifest?(site)

        [
          "/plugin marketplace add #{Jekyll::SkillPages.repo_slug(site)}",
          "/plugin install #{Jekyll::SkillPages.marketplace_name(site)}@#{slug}",
          '/reload-plugins'
        ]
      end

      def to_data(skill_slugs:)
        resolved_skills = skill_slugs.empty? ? declared_skills : skill_slugs

        {
          'slug' => slug,
          'name' => name,
          'description' => description,
          'version' => version,
          'skills' => resolved_skills,
          'declared_skills' => declared_skills,
          'skill_count' => resolved_skills.size,
          'mcp_path' => mcp_path,
          'mcp_url' => mcp_url,
          'source_path' => source_path,
          'source_url' => source_url,
          'install_commands' => install_commands,
          'primary_install_command' => primary_install_command
        }
      end

      private

      def manifest
        @manifest ||= JSON.parse(File.read(File.join(folder, '.claude-plugin', 'plugin.json')))
      end
    end
  end
end
