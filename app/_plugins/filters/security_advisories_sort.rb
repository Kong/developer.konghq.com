# frozen_string_literal: true

module Jekyll
  # Sorts security advisories newest first by publication date, breaking ties
  # by title ascending, so the index order is deterministic across builds.
  # Liquid's own `sort` is not stable, so chaining sorts cannot guarantee the
  # tie order.
  module SecurityAdvisoriesSort
    def security_advisories_sort(advisories)
      advisories.sort do |a, b|
        a_published = a['advisory']['published'].to_s
        b_published = b['advisory']['published'].to_s
        if a_published == b_published
          a['title'].to_s <=> b['title'].to_s
        else
          b_published <=> a_published
        end
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::SecurityAdvisoriesSort)
