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

      doc.css('h2').each do |h2|
        slug = h2['id']
        title = h2.text

        # Build the custom wrapper
        wrapper = build_wrapper(h2, slug, title)

        # Move content between this h2 and the next one into the wrapper
        move_sibling_content_into_wrapper(h2, wrapper)

        # Replace the original h2 with the wrapper
        h2.replace(wrapper)
      end

      # Return the modified HTML as a string
      doc.to_html
    end

    def build_wrapper(h2, slug, title)
      Nokogiri::HTML::DocumentFragment.parse <<-HTML
        <div class="flex flex-col gap-3">
            #{h2.to_html}
            <div class="content"></div>
        </div>
      HTML
    end

    def move_sibling_content_into_wrapper(h2, wrapper)
      current_node = h2.next_sibling

      # Skip over non-element nodes (like text or whitespace)
      while current_node && !current_node.element?
        current_node = current_node.next_sibling
      end

      while current_node && current_node.name != 'h2'
        next_node = current_node.next_sibling
        wrapper.at_css('.content').add_child(current_node)

        # Move to the next sibling, skipping over non-element nodes
        current_node = next_node
        while current_node && !current_node.element?
          current_node = current_node.next_sibling
        end
      end
    end
  end
end
