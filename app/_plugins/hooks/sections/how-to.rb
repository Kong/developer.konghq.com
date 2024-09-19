require 'nokogiri'

module SectionWrapper
  class HowTo < Base
    def section_title(h2, slug, title)
      Nokogiri::HTML::DocumentFragment.parse <<-HTML
        <a aria-label="Anchor" href="##{slug}" title="#{title}" class="header-link flex items-baseline justify-between hover:no-underline accordion-trigger">
          #{h2.to_html}
          <span class="fa fa-chevron-down text-terciary rotate-180" aria-hidden="true"></span>
        </a>
      HTML
    end

    def build_wrapper(section_title = '')
      wrapper = if section_title != ''
        <<-HTML
          <div class="flex flex-col gap-4 border-b border-primary/5 pb-8 accordion-item">
            #{section_title}
            <div class="content accordion-panel"></div>
          </div>
        HTML
      else
        <<-HTML
        <div class="flex flex-col gap-4 border-b border-primary/5 pb-8">
          <div class="content"></div>
        </div>
      HTML
      end
      Nokogiri::HTML::DocumentFragment.parse(wrapper)
    end
  end
end