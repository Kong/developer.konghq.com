require 'nokolexbor'

module SectionWrapper
  class Base
    def self.make_for(page)
      if page.is_a?(Jekyll::Document) && page.collection.label == 'how-tos'
        HowTo.new(page)
      elsif page.data['content_type'] == 'cookbook'
        Cookbook.new(page)
      else
        new(page)
      end
    end

    def initialize(page)
      @page = page
    end

    def process
      @page.content = wrap_sections(@page.content) unless @page.data['no_wrap']
    end

    private

    # Build the output as a string instead of mutating the parsed doc.
    # Cross-fragment node moves trigger a use-after-free in Nokolexbor; this
    # avoids the issue entirely by only reading from the parsed tree.
    def wrap_sections(content)
      doc = Nokolexbor::DocumentFragment.parse(content)
      return build_wrapper_string('', '', doc.inner_html) unless doc.at_css('h2')

      pre, sections = split_by_heading(doc.children, 'h2')
      out = +''
      out << build_wrapper_string('', '', nodes_to_html(pre)) unless pre.empty?
      sections.each { |h2, body| out << build_section_string(h2, body) }
      out
    end

    def split_by_heading(nodes, tag)
      groups = nodes.to_a.slice_when { |_, b| heading?(b, tag) }.to_a
      pre = heading?(groups.first&.first, tag) ? [] : (groups.shift || [])
      sections = groups.map { |g| [g.first, g.drop(1)] }
      [pre, sections]
    end

    def heading?(node, tag)
      node&.element? && node.name == tag
    end

    def build_section_string(h2, body_nodes)
      build_wrapper_string(
        section_title(h2, h2['id'], h2.content),
        h2['data-deployment-topology'],
        wrap_section_body(body_nodes)
      )
    end

    def wrap_section_body(nodes)
      nodes_to_html(nodes)
    end

    def nodes_to_html(nodes)
      nodes.map(&:to_html).join
    end

    def section_title(h2, _slug, _title)
      h2.to_html
    end

    def build_wrapper_string(title_html, _topology, body_html)
      <<~HTML
        <div class="flex flex-col gap-4 heading-section">
          #{title_html}
          <div class="content">#{body_html}</div>
        </div>
      HTML
    end
  end
end
