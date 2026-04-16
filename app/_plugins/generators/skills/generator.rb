# frozen_string_literal: true

module Jekyll
  module SkillPages
    SKILLS_REPO = ENV.fetch('SKILLS_REPO', 'kong-skills')

    def self.demote_headings(text)
      text.lines.filter_map do |line|
        next nil if line.match?(/^# [^#]/)

        line.match?(/^##/) ? "##{line}" : line
      end.join
    end

    class Generator
      def self.run(site)
        new(site).run
      end

      attr_reader :site

      def initialize(site)
        @site = site
      end

      def run
        base_dir = File.expand_path('..', site.source)
        load_install_tabs(base_dir)

        skills_path = File.join(base_dir, SKILLS_REPO, 'skills')
        return unless Dir.exist?(skills_path)

        Dir.glob(File.join(skills_path, '*/')).each do |folder|
          slug = File.basename(folder)
          skill = Jekyll::SkillPages::Skill.new(folder:, slug:)
          skill.metadata # force read to fail fast
          generate_overview_page(skill)
        rescue Errno::ENOENT
          next
        end
      end

      private

      INSTALL_EXCLUDES = %w[README.md].freeze

      def load_install_tabs(base_dir)
        install_path = File.join(base_dir, SKILLS_REPO, 'docs', 'install')
        return unless Dir.exist?(install_path)

        site.data['skill_install_tabs'] = Dir.glob(File.join(install_path, '*.md'))
          .reject { |f| INSTALL_EXCLUDES.include?(File.basename(f)) }
          .map { |f| parse_install_file(f) }
          .sort_by { |tab| tab['title'] }
      end

      def parse_install_file(file)
        raw = File.read(file)
        slug = File.basename(file, '.md')

        title = raw.lines.first&.match(/^#\s+(.+)/)&.captures&.first || slug

        processed = Jekyll::SkillPages.demote_headings(raw)

        repo_url = site.config.dig('repos', 'skills')
        if repo_url
          processed = processed.gsub(%r{\]\(\.\.\/\.\.\/(.*?)\)}, "](#{repo_url}/blob/main/\\1)")
        end

        { 'title' => title.strip, 'slug' => slug, 'content' => processed }
      end

      def generate_overview_page(skill)
        overview = Jekyll::SkillPages::Pages::Overview
                   .new(skill:)
                   .to_jekyll_page

        site.data['skills'][skill.slug] = overview
        site.pages << overview
      end
    end
  end
end
