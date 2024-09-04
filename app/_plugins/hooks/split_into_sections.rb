require 'nokogiri'

Jekyll::Hooks.register :documents, :post_convert do |doc, payload|
  next if doc.collection.label != 'how-tos'

  content = doc.content
  doc.content = wrap_sections_with_nokogiri(content)
end

def wrap_sections_with_nokogiri(content)
  # Parse the HTML content with Nokogiri
  doc = Nokogiri::HTML::DocumentFragment.parse(content)

  # Find all h2 elements
  doc.css('h2').each do |h2|
    # Create the wrapping structure
    slug = h2['id']
    title = h2.text

    wrapper = Nokogiri::HTML::DocumentFragment.parse <<-HTML
      <div class="flex flex-col gap-3" aria-expanded="true">
        <a href="##{slug}" title="#{title}" class="flex items-baseline justify-between">
          #{h2.to_html}
          <span class="fa fa-chevron-down text-terciary rotate-180" aria-hidden="true"></span>
        </a>
        <div></div>
      </div>
    HTML

    current_node = h2.next_sibling
    while current_node && !current_node.element?
      current_node = current_node.next_sibling
    end

    while current_node && current_node.name != 'h2'
      next_node = current_node.next_sibling
      wrapper.at_css('div > div').add_child(current_node)
      current_node = next_node

      while current_node && !current_node.element?
        current_node = current_node.next_sibling
      end
    end
    # Replace the original h2 with the wrapped structure
    h2.replace(wrapper)
  end

  # Return the modified HTML as a string
  doc.to_html
end
