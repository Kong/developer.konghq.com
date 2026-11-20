# frozen_string_literal: true

# Returns the `aria-labelledby` references in a parsed page that no element on that page defines.
def dangling_aria_labelledby_ids(html)
  ids = html.all('[id]').map { |element| element[:id] }
  references = html.all('[aria-labelledby]').flat_map { |element| element['aria-labelledby'].split }

  (references - ids).uniq
end
