# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/object/deep_dup'
require 'fileutils'

module Jekyll
  class MarkdownPagesGenerator < Generator
    priority :lowest

    def generate(site)
      @site = site
      site.config['markdown_pages_to_render'] ||= []

      return if site.config.dig('skip', 'llm_pages')

      # TODO: Do the same for collections
      site.pages.each do |page|
        next if page.data['llm'] == false
        next if page.path.start_with?('assets/')
        next if page.path.start_with?('_api/')

        site.config['markdown_pages_to_render'] << MarkdownPage.new(site:, page:)
      end
    end
  end

  class MarkdownPage < Jekyll::Page
    def initialize(site:, page:)
      @site = site
      @page = page

      process("#{File.basename(@page.url)}.md")

      @data = page.data.deep_dup
      @content = page.content
      @data.delete('permalink')

      @dir = File.dirname(@page.url)

      @data['output_format'] = 'markdown'
    end

    def render
      payload = @site.site_payload
      payload['page'] = to_liquid

      info = { registers: { site: @site, page: to_liquid },
               strict_filters: @site.config['liquid']['strict_filters'],
               strict_variables: @site.config['liquid']['strict_variables'] }

      rendered_content = Liquid::Template.parse(@content).render!(payload, info)

      layout = @site.layouts['llm']
      layout_payload = payload.merge('content' => rendered_content)
      Liquid::Template.parse(layout.content).render!(layout_payload, info)
    end

    def output_ext
      '.md'
    end

    def output_path
      File.join(@site.dest, url)
    end

    def write
      FileUtils.mkdir_p(File.dirname(output_path))
      File.write(output_path, render)
    end
  end
end
