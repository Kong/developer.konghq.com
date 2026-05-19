# frozen_string_literal: true

require_relative '../../../lib/site_accessor'

module Jekyll
  module SkillPages
    module Pages
      class Overview
        include Jekyll::SiteAccessor

        def self.url(skill)
          "/skills/#{skill.slug}/"
        end

        def initialize(skill:)
          @skill = skill
        end

        def to_jekyll_page
          CustomJekyllPage.new(site:, page: self)
        end

        TEMPLATE = File.read('app/_includes/skills/overview.md')

        def content
          TEMPLATE
        end

        def dir
          url
        end

        def url
          @url ||= self.class.url(@skill)
        end

        def data
          {
            'title' => @skill.name,
            'content_type' => 'skill',
            'description' => @skill.description,
            'version' => @skill.version,
            'author' => @skill.author,
            'slug' => @skill.slug,
            'layout' => 'skill',
            'breadcrumbs' => ['/skills/'],
            'no_edit_link' => true,
            'license' => @skill.license,
            'license_is_file' => @skill.license_file?,
            'license_url' => @skill.license_url,
            'allowed_tools' => @skill.allowed_tools,
            'scripts' => @skill.scripts?,
            'scripts_url' => @skill.scripts_url,
            'references' => @skill.references?,
            'references_url' => @skill.references_url,
            'assets' => @skill.assets?,
            'assets_url' => @skill.assets_url,
            'skill_content' => @skill.processed_content,
            'products' => @skill.products,
            'skill_category' => @skill.category,
            'tags' => @skill.tags,
            'plugin_slug' => @skill.plugin_slug,
            'plugin_name' => @skill.plugin_name,
            'plugin_path' => @skill.plugin_path,
            'plugin_source_url' => @skill.plugin_source_url,
            'plugin_page_url' => @skill.plugin_page_url,
            'source_path' => @skill.source_path,
            'source_url' => @skill.source_url,
            'toc' => false
          }
        end

        def relative_path
          @relative_path ||= File.join(
            Jekyll::SkillPages.skills_repo_path(site), @skill.source_path, 'SKILL.md'
          )
        end
      end
    end
  end
end
