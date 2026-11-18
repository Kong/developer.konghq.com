# frozen_string_literal: true

module NoTocHeadingsFilter # rubocop:disable Style/Documentation
  # Matches the opening tag of an h2..h6 heading, capturing its level and any
  # attributes, so the class can be added without touching the heading text.
  HEADING_OPENING_TAG = /<h([2-6])((?:\s[^>]*)?)>/i
  CLASS_ATTRIBUTE = /\bclass\s*=\s*"([^"]*)"/

  def no_toc_headings(input)
    input.to_s.gsub(HEADING_OPENING_TAG) do
      level = Regexp.last_match(1)
      attributes = Regexp.last_match(2)

      "<h#{level}#{attributes_with_no_toc(attributes)}>"
    end
  end

  private

  def attributes_with_no_toc(attributes)
    existing = attributes[CLASS_ATTRIBUTE, 1]

    return attributes if existing&.split&.include?('no_toc')

    if existing
      attributes.sub(CLASS_ATTRIBUTE) { |match| match.sub(existing, "#{existing} no_toc") }
    else
      %( class="no_toc"#{attributes})
    end
  end
end

Liquid::Template.register_filter(NoTocHeadingsFilter)
