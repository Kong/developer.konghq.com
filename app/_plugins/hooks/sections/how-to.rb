require 'nokogiri'

module SectionWrapper
  class HowTo < Base
    def section_title(h2, slug, title)
      h2.add_class('how-to-step--title')
      Nokogiri::HTML::DocumentFragment.parse <<-HTML
        <a aria-label="Anchor" href="##{slug}" title="#{title}" class="link-anchor flex items-center justify-between hover:no-underline accordion-trigger">
          <div class="flex items-center gap-2 group w-full">
          #{h2.to_html}
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

    def build_wrapper(section_title = '', topology = '')
      topology = "data-deployment-topology=\"#{topology}\"" if !topology.nil? && !topology.empty?
      wrapper = if section_title != ''
                  <<-HTML
          <div #{topology} class="flex flex-col gap-4 border-b border-primary/5 pb-8 accordion-item">
            #{section_title}
            <div class="content accordion-panel"></div>
          </div>
                  HTML
                else
                  <<-HTML
        <div #{topology} class="flex flex-col gap-4 border-b border-primary/5 pb-8">
          <div class="content"></div>
        </div>
                  HTML
                end
      Nokogiri::HTML::DocumentFragment.parse(wrapper)
    end
  end
end
