# frozen_string_literal: true

module WorksOnFilters # rubocop:disable Style/Documentation
  def works_on_incompatibilities(values)
    site = @context.registers[:site]
    works_on = site.data.dig('schemas', 'frontmatter', 'base', 'properties', 'works_on', 'items', 'enum')

    works_on - values
  end
end

Liquid::Template.register_filter(WorksOnFilters)
