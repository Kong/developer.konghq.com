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
    #
    # Boundaries: an h2 starts a new section; a pre-wrapped `.heading-section`
    # element (e.g. an `{% entity_example %}` block) is emitted as-is and
    # flushes any open section. Otherwise content accumulates into the
    # current h2 section, or into the pre-h2 bucket if no h2 is open yet.
    def wrap_sections(content)
      doc = Nokolexbor::DocumentFragment.parse(content)
      return build_wrapper_string('', '', doc.inner_html) unless any_boundary?(doc.children)

      out, pre, h2, body = +'', [], nil, nil
      doc.children.each do |node|
        next if whitespace_only_text?(node)
        if heading?(node, 'h2')
          out << flush_pending(pre, h2, body); pre = []; h2 = node; body = []
        elsif pre_wrapped_section?(node)
          out << flush_pending(pre, h2, body); out << node.to_html
          pre = []; h2 = nil; body = nil
        elsif h2
          body << node
        else
          pre << node
        end
      end
      out << flush_pending(pre, h2, body)
      out
    end

    def flush_pending(pre, h2, body)
      return build_section_string(h2, body) if h2
      return build_wrapper_string('', '', nodes_to_html(pre)) if pre.any?
      ''
    end

    def any_boundary?(nodes)
      nodes.any? { |n| heading?(n, 'h2') || pre_wrapped_section?(n) }
    end

    def pre_wrapped_section?(node)
      return false unless node.element?
      (node['class'] || '').split(/\s+/).include?('heading-section')
    end

    def whitespace_only_text?(node)
      return false if node.element?
      node.to_html.strip.empty?
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
