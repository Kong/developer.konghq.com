# frozen_string_literal: true

require 'json'
require 'pathname'
require_relative 'power'

module Jekyll
  module SkillPages
    def self.skills_repo_path(site)
      ENV['SKILLS_REPO_PATH'] || ENV['SKILLS_REPO'] || site.config['skills_repo_path'] || 'app/.repos/skills'
    end

    def self.base_dir(site)
      File.expand_path('..', site.source)
    end

    def self.repo_root(site)
      File.expand_path(skills_repo_path(site), base_dir(site))
    end

    def self.repo_branch(site)
      site.config['skills_repo_branch'] || 'main'
    end

    def self.repo_slug(site)
      site.config['skills_repo_slug'] || site.config.dig('repos', 'skills').to_s.sub(%r{\Ahttps://github\.com/}, '').sub(%r{/\z}, '')
    end

    def self.marketplace_name(site)
      manifest_path = File.join(repo_root(site), '.claude-plugin', 'marketplace.json')
      return File.basename(repo_slug(site)) unless File.exist?(manifest_path)

      JSON.parse(File.read(manifest_path)).fetch('name', File.basename(repo_slug(site)))
    rescue JSON::ParserError
      File.basename(repo_slug(site))
    end

    def self.marketplace_manifest?(site)
      File.exist?(File.join(repo_root(site), '.claude-plugin', 'marketplace.json'))
    end

    def self.repo_tree_url(site, path)
      "#{site.config.dig('repos', 'skills')}/tree/#{repo_branch(site)}/#{path}"
    end

    def self.repo_blob_url(site, path)
      "#{site.config.dig('repos', 'skills')}/blob/#{repo_branch(site)}/#{path}"
    end

    def self.repo_raw_url(site, path)
      raw_base = site.config.dig('repos', 'skills_raw') || site.config.dig('repos', 'skills').to_s.sub('github.com', 'raw.githubusercontent.com')
      "#{raw_base}/#{repo_branch(site)}/#{path}"
    end

    def self.demote_headings(text)
      text.lines.filter_map do |line|
        next nil if line.match?(/^# [^#]/)

        line.match?(/^##/) ? "##{line}" : line
      end.join
    end

    def self.normalize_repo_path(current_relative_dir, candidate)
      return if candidate.nil? || candidate.empty?

      cleaned = candidate.gsub(%r{\A<|>\z}, '')
      return if cleaned.empty?

      joined = if cleaned.start_with?('/')
                 cleaned.delete_prefix('/')
               else
                 File.join(current_relative_dir, cleaned)
               end

      Pathname.new(joined).cleanpath.to_s
    end

    def self.absolute_target?(target)
      cleaned = target.to_s.strip
      cleaned.start_with?('#', '/', 'http://', 'https://', 'mailto:', 'tel:', 'data:')
    end

    def self.rewrite_relative_links(text, site:, source_relative_path:)
      repo_root_path = repo_root(site)

      text.gsub(/(!?)\[(.*?)\]\(([^)]+)\)/m) do
        marker = Regexp.last_match(1)
        label = Regexp.last_match(2)
        target = Regexp.last_match(3)

        next Regexp.last_match(0) if absolute_target?(target)

        path, anchor = target.split('#', 2)
        normalized_path = normalize_repo_path(File.dirname(source_relative_path), path)
        next Regexp.last_match(0) if normalized_path.nil? || normalized_path.empty?

        resolved_path = File.join(repo_root_path, normalized_path)
        rewritten_target = if marker == '!'
                             repo_raw_url(site, normalized_path)
                           elsif File.directory?(resolved_path) || path.end_with?('/')
                             repo_tree_url(site, normalized_path)
                           else
                             repo_blob_url(site, normalized_path)
                           end

        rewritten_target = "#{rewritten_target}##{anchor}" if anchor && marker != '!'
        "#{marker}[#{label}](#{rewritten_target})"
      end
    end

    class Generator
      def self.run(site)
        new(site).run
      end

      attr_reader :site

      def initialize(site)
        @site = site
        @skills = []
        @plugins = []
        @power = nil
        @repo_root = Jekyll::SkillPages.repo_root(site)
      end

      def run
        return if site.config.dig('skip', 'skills')

        load_install_tabs
        return unless Dir.exist?(@repo_root)

        discover_power
        discover_plugins_and_skills
        site.data['skills_power'] = @power&.to_data
        site.data['skills_filters'] = build_filters
        Jekyll::SkillPages::Discovery.generate(site, @skills)
      end

      private

      INSTALL_EXCLUDES = %w[README.md].freeze

      def discover_plugins_and_skills
        plugin_folders = Dir.glob(File.join(@repo_root, 'plugins', '*/'))
                            .select { |folder| File.exist?(File.join(folder, '.claude-plugin', 'plugin.json')) }
                            .sort

        if plugin_folders.any?
          plugin_folders.each do |folder|
            plugin = Jekyll::SkillPages::Plugin.new(site:, folder:, slug: File.basename(folder))
            @plugins << plugin

            Dir.glob(File.join(folder, 'skills', '*/')).sort.each do |skill_folder|
              load_skill(skill_folder, plugin:)
            end
          end
        else
          Dir.glob(File.join(@repo_root, 'skills', '*/')).sort.each do |skill_folder|
            load_skill(skill_folder)
          end
        end

        site.data['skills_plugins'] = @plugins.map do |plugin|
          skill_slugs = @skills.select { |skill| skill.plugin_slug == plugin.slug }.map(&:slug)
          plugin.to_data(skill_slugs:)
        end
      end

      def discover_power
        power_file = File.join(@repo_root, 'POWER.md')
        return unless File.exist?(power_file)

        @power = Jekyll::SkillPages::Power.new(site:, file: power_file)
      end

      def load_skill(folder, plugin: nil)
        skill = Jekyll::SkillPages::Skill.new(site:, folder:, slug: File.basename(folder), plugin:)
        skill.metadata
        @skills << skill
        generate_overview_page(skill)
      rescue Errno::ENOENT
        nil
      end

      def load_install_tabs
        install_path = File.join(@repo_root, 'docs', 'install')
        return unless Dir.exist?(install_path)

        site.data['skill_install_tabs'] = Dir.glob(File.join(install_path, '*.md'))
                                             .reject { |file| INSTALL_EXCLUDES.include?(File.basename(file)) }
                                             .map { |file| parse_install_file(file) }
                                             .sort_by { |tab| tab['title'] }
      end

      def parse_install_file(file)
        raw = File.read(file)
        slug = File.basename(file, '.md')
        title = raw.lines.first&.match(/^#\s+(.+)/)&.captures&.first || slug
        source_relative_path = Pathname.new(file).relative_path_from(Pathname.new(@repo_root)).to_s
        processed = Jekyll::SkillPages.demote_headings(
          Jekyll::SkillPages.rewrite_relative_links(raw, site:, source_relative_path:)
        )

        {
          'title' => title.strip,
          'slug' => slug,
          'icon' => "/assets/icons/ai-tools/#{slug}.svg",
          'content' => processed
        }
      end

      def generate_overview_page(skill)
        overview = Jekyll::SkillPages::Pages::Overview.new(skill:).to_jekyll_page
        site.data['skills'][skill.slug] = overview
        site.pages << overview
      end

      def build_filters
        {
          'plugins' => @plugins.sort_by { |plugin| plugin.name.downcase }.map do |plugin|
            filter_option(plugin.slug, plugin.name)
          end,
          'products' => build_label_filters(@skills.flat_map(&:products)),
          'categories' => build_label_filters(@skills.map(&:category))
        }
      end

      def build_label_filters(values)
        values.filter_map do |value|
          next if value.nil?

          label = value.to_s.strip
          next if label.empty?

          filter_option(Jekyll::Utils.slugify(label), label)
        end.uniq { |option| option['value'] }
              .sort_by { |option| option['label'].downcase }
      end

      def filter_option(value, label)
        {
          'value' => value,
          'label' => label
        }
      end
    end
  end
end
