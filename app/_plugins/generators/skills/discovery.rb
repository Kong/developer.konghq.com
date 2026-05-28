# frozen_string_literal: true

require 'json'

module Jekyll
  module SkillPages
    class Discovery
      def self.generate(site, skills)
        new(site, skills).run
      end

      def initialize(site, skills)
        @site = site
        @skills = skills
      end

      def run
        return if @skills.empty?

        index_entries = @skills.map do |skill|
          generate_skill_pages(@site, skill)
          {
            'name' => skill.slug,
            'description' => skill.description,
            'files' => skill.all_files
          }
        end

        generate_index(@site, index_entries)
      end

      def generate_skill_pages(site, skill)
        skill.all_files.each do |relative_path|
          dir = File.join(well_known_dir, skill.slug, File.dirname(relative_path))
          dir = File.join(well_known_dir, skill.slug) if File.dirname(relative_path) == '.'
          filename = File.basename(relative_path)

          site.static_files << Pages::StaticSkillFile.new(
            site, skill.folder, dir, filename, relative_path
          )
        end
      end

      def generate_index(site, entries)
        page = PageWithoutAFile.new(site, site.source, well_known_dir, 'index.json')
        page.data['llm'] = false
        page.data['layout'] = nil
        page.content = JSON.pretty_generate({ 'skills' => entries })
        site.pages << page
      end

      def well_known_dir
        @well_known_dir ||= @site.config.dig('well-known', 'skills')
      end
    end
  end
end
