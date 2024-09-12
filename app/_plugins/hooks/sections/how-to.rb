require 'nokogiri'

module SectionWrapper
  class HowTo < Base
    def build_wrapper(h2, slug, title)
        Nokogiri::HTML::DocumentFragment.parse <<-HTML
            <div class="flex flex-col gap-4 collapsible" aria-expanded="true">
                <a aria-label="Anchor" href="##{slug}" title="#{title}" class="header-link flex items-baseline justify-between hover:no-underline">
                #{h2.to_html}
                <span class="fa fa-chevron-down text-terciary rotate-180" aria-hidden="true"></span>
                </a>
                <div class="content"></div>
            </div>
        HTML
      end
  end
end