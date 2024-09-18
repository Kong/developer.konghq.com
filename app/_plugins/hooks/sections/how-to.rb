require 'nokogiri'

module SectionWrapper
  class HowTo < Base
    def section_title(h2, slug, title)
      Nokogiri::HTML::DocumentFragment.parse <<-HTML
        <a aria-label="Anchor" href="##{slug}" title="#{title}" class="header-link flex items-baseline justify-between hover:no-underline">
          #{h2.to_html}
          <span class="fa fa-chevron-down text-terciary rotate-180" aria-hidden="true"></span>
        </a>
      HTML
    end

    def build_wrapper(section_title = '')
      Nokogiri::HTML::DocumentFragment.parse <<-HTML
        <div class="flex flex-col gap-4 step" aria-expanded="true">
            #{section_title}
            <div class="content"></div>
        </div>
      HTML
    end
  end
end