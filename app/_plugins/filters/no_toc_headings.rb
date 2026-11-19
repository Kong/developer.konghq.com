# frozen_string_literal: true

module NoTocHeadingsFilter # rubocop:disable Style/Documentation
  # Matches the opening tag of an h2..h6 heading. A quoted attribute value may
  # contain `>`, so the attribute run lets quoted strings pass through whole.
  HEADING_OPENING_TAG = /<h([2-6])((?:\s+(?:[^>"']|"[^"]*"|'[^']*')*)?)>/i
  # Matches a class attribute in any of the quoting styles HTML allows. The
  # lookbehind keeps `data-class` and similar attributes from matching.
  CLASS_ATTRIBUTE = /(?<![-\w])class\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'>]+))/

  def no_toc_headings(input)
    input.to_s.gsub(HEADING_OPENING_TAG) do
      "<h#{Regexp.last_match(1)}#{attributes_with_no_toc(Regexp.last_match(2))}>"
    end
  end

  private

  def attributes_with_no_toc(attributes)
    match = attributes.match(CLASS_ATTRIBUTE)

    return %( class="no_toc"#{attributes}) unless match

    classes = (match[1] || match[2] || match[3]).split
    return attributes if classes.include?('no_toc')

    attributes.sub(match[0], %(class="#{(classes << 'no_toc').join(' ')}"))
  end
end

Liquid::Template.register_filter(NoTocHeadingsFilter)
