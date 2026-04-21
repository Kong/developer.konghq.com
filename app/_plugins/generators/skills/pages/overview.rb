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
            'description' => @skill.description,
            'version' => @skill.version,
            'author' => @skill.author,
            'slug' => @skill.slug,
            'layout' => 'skill',
            'breadcrumbs' => ['/skills/'],
            'no_edit_link' => true,
            'content_type' => 'skill',
            'license' => @skill.license,
            'license_is_file' => @skill.license_file?,
            'allowed_tools' => @skill.allowed_tools,
            'scripts' => @skill.scripts?,
            'references' => @skill.references?,
            'assets' => @skill.assets?,
            'skill_content' => @skill.processed_content,
            'products' => @skill.products,
            'llm' => false,
            'toc' => false
          }
        end

        def relative_path
          @relative_path ||= File.join(
            Jekyll::SkillPages.skills_repo_path(site), 'skills', @skill.slug, 'SKILL.md'
          )
        end
      end
    end
  end
end
