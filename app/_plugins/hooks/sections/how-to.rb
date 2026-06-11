module SectionWrapper
  class HowTo < Base
    def section_title(h2, slug, title)
      h2.add_class('how-to-step--title')
      <<~HTML
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

    def build_wrapper_string(title_html, topology, body_html)
      topology_attr = topology && !topology.empty? ? %( data-deployment-topology="#{topology}") : ''
      if title_html.to_s.strip.empty?
        <<~HTML
          <div#{topology_attr} class="flex flex-col gap-4 border-b border-primary/5 pb-8">
            <div class="content">#{body_html}</div>
          </div>
        HTML
      else
        <<~HTML
          <div#{topology_attr} class="flex flex-col gap-4 border-b border-primary/5 pb-8 accordion-item">
            #{title_html}
            <div class="content accordion-panel">#{body_html}</div>
          </div>
        HTML
      end
    end
  end
end
