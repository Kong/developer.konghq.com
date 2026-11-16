# frozen_string_literal: true

require_relative '../lib/security_advisory_summary'

module Jekyll
  # Returns the products, severity, fixed versions and published date the
  # security index shows for an advisory document.
  module SecurityAdvisorySummaryFilter
    def security_advisory_summary(doc)
      Jekyll::SecurityAdvisorySummary.new(doc, @context.registers[:site].config).to_h
    end
  end
end

Liquid::Template.register_filter(Jekyll::SecurityAdvisorySummaryFilter)
