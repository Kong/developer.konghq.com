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

      site.pages.each do |page|
        next if page.data['llm'] == false
        next if page.data['published'] == false
        next if page.path.start_with?('assets/')

        site.config['markdown_pages_to_render'] << MarkdownPage.new(site:, page:)
      end

      site.collections.each do |name, collection|
        collection.docs.each do |page|
          next if page.data['llm'] == false
          next if page.data['published'] == false

          site.config['markdown_pages_to_render'] << MarkdownPage.new(site:, page:)
        end
      end
    end
  end

  class MarkdownPage < Jekyll::Page
    def initialize(site:, page:)
      @site = site
      @page = page

      process("#{File.basename(@page.url)}.md")

      @data = { 'output_format' => 'markdown', 'layout' => 'llm' }
      @content = page.respond_to?(:markdown_content) ? page.markdown_content : @page.content
      @dir = File.dirname(@page.url)
    end

    def render
      # We need to clone it here so we are sure that other generators ran
      @data.merge!(@page.data.deep_dup.except('permalink'))

      payload = @site.site_payload
      payload['page'] = to_liquid

      info = { registers: { site: @site, page: to_liquid },
               strict_filters: @site.config['liquid']['strict_filters'],
               strict_variables: @site.config['liquid']['strict_variables'] }

      rendered_content = Liquid::Template.parse(@content, { line_numbers: true }).render!(payload, info)

      layout = @site.layouts['llm']
      layout_payload = payload.merge('content' => rendered_content, 'page' => to_liquid)

      content = Liquid::Template.parse(layout.content, { line_numbers: true }).render!(layout_payload, info)
      post_process_content(content)
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

    def post_process_content(content)
      content.gsub!(/<!--\s*vale on\s*-->/, '')
      content.gsub!(/<!--\s*vale off\s*-->/, '')
      content
    end
  end
end
