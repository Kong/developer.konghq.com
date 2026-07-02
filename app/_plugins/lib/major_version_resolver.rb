# frozen_string_literal: true

module Jekyll
  class MajorVersionResolver
    def self.process(product_data:, major:)
      product_data.fetch('previous_major_url_segment').gsub('<major>', major.to_s)
    end
  end
end
