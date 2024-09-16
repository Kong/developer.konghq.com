require 'nokogiri'

module SectionWrapper
  class Base

    def self.make_for(page)
      if page.is_a?(Jekyll::Document) && page.collection.label == 'how-tos'
        HowTo.new(page)
      else
        new(page)
      end
    end

    def initialize(page)
      @page = page
    end

    def process
      @page.content = wrap_sections(@page.content)
    end

    private

    def wrap_sections(content)
      doc = Nokogiri::HTML::DocumentFragment.parse(content)

      first_h2 = doc.at_css('h2')

      if first_h2
        # Wrap content before the first h2
        content = wrap_content(doc, doc.children.take_while { |node| node != first_h2 })

        if content && content.children.any?
          doc.children.first.add_previous_sibling(content)
        end

        doc.css('h2').each do |h2|
          slug = h2['id']
          title = h2.text

          wrapper = build_wrapper(section_title(h2, slug, title))

          # Move content between this h2 and the next one into the wrapper
          move_sibling_content_into_wrapper(h2, wrapper)

          # Replace the original h2 with the wrapper
          h2.replace(wrapper)
        end
      else
        wrapper = wrap_content(doc, doc.children)
        doc.children = wrapper.children
      end

      # Return the modified HTML as a string
      doc.to_html
    end

    def wrap_content(doc, nodes)
      return if nodes.empty?

      wrapper = build_wrapper
      nodes.each { |node| wrapper.at_css('.content').add_child(node) }
      wrapper
    end

    def build_wrapper(section_title = '')
      Nokogiri::HTML::DocumentFragment.parse <<-HTML
        <div class="flex flex-col gap-4">
            #{section_title}
            <div class="content"></div>
        </div>
      HTML
    end

    def move_sibling_content_into_wrapper(h2, wrapper)
      current_node = h2.next_element

      while current_node && current_node.name != 'h2'
        next_node = current_node.next_element
        wrapper.at_css('.content').add_child(current_node)
        current_node = next_node
      end
    end

    def section_title(h2, slug, title)
      h2.to_html
    end
  end
end
