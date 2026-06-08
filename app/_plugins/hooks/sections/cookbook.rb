# frozen_string_literal: true

require 'cgi'
require_relative 'base'
require_relative 'how-to'

module SectionWrapper
  class Cookbook < HowTo
    private

    # Hook into the section-body step so h4 wrapping happens in the same pass
    # as h2 wrapping, with no re-parse and no cross-fragment node moves.
    def wrap_section_body(nodes)
      pre, sections = split_by_heading(nodes, 'h4')
      out = +''
      out << nodes_to_html(pre)
      sections.each { |h4, body| out << build_h4_section_string(h4, body) }
      out
    end

    def build_h4_section_string(h4, body_nodes)
      build_h4_wrapper_string(
        h4_section_title(h4, h4['id'], h4.content),
        nodes_to_html(body_nodes)
      )
    end

    def h4_section_title(h4, slug, title)
      escaped_title = CGI.escapeHTML(title)
      <<~HTML
        <a aria-label="Anchor" href="##{slug}" title="#{escaped_title}" class="link-anchor flex items-center justify-between hover:no-underline accordion-trigger">
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

    def build_h4_wrapper_string(title_html, body_html)
      <<~HTML
        <div class="accordion">
          <div class="flex flex-col gap-4 border-b border-primary/5 accordion-item">
            #{title_html}
            <div class="content accordion-panel">#{body_html}</div>
          </div>
        </div>
      HTML
    end
  end
end
