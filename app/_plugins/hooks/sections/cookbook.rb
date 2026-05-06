# frozen_string_literal: true

require 'nokogiri'
require_relative 'base'
require_relative 'how-to'

module SectionWrapper
  class Cookbook < HowTo
    private

    def wrap_sections(content)
      html = super(content)
      wrap_h4_sections(html)
    end

    def wrap_h4_sections(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      doc.css('.accordion-panel').each do |panel|
        h4s = panel.children.select { |n| n.element? && n.name == 'h4' }
        next if h4s.empty?

        h4s.each do |h4|
          slug = h4['id']
          title = h4.content

          wrapper = build_h4_wrapper(h4_section_title(h4, slug, title))
          content_div = wrapper.at_css('.content')

          current_node = h4.next_element
          while current_node && !%w[h1 h2 h3 h4].include?(current_node.name)
            next_node = current_node.next_element
            content_div.add_child(current_node)
            current_node = next_node
          end

          h4.replace(wrapper)
        end
      end

      doc.to_html
    end

    def h4_section_title(h4, slug, title)
      Nokogiri::HTML::DocumentFragment.parse <<-HTML
        <a aria-label="Anchor" href="##{slug}" title="#{title}" class="link-anchor flex items-center justify-between hover:no-underline accordion-trigger" id="#{slug}">
          <div class="flex items-center gap-2 group w-full">
            #{h4.to_html}
            <span class="text-brand hidden link-anchor-icon group-hover:flex">
              #{File.read('app/assets/icons/link.svg')}
            </span>
          </div>
          <span class="inline-flex chevron-icon rotate-180" aria-hidden="true">
            #{File.read('app/assets/icons/chevron-down.svg')}
          </span>
        </a>
      HTML
    end

    def build_h4_wrapper(section_title)
      Nokogiri::HTML::DocumentFragment.parse <<-HTML
        <div class="accordion">
          <div class="flex flex-col gap-4 border-b border-primary/5 accordion-item">
            #{section_title}
            <div class="content accordion-panel"></div>
          </div>
        </div>
      HTML
    end
  end
end
