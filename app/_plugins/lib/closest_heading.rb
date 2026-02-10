# frozen_string_literal: true

module Jekyll
  class ClosestHeading # rubocop:disable Style/Documentation
    def initialize(page, tag)
      @page = page
      @tag = tag
    end

    def level
      last_heading_level = 1

      content.lines.each do |line|
        last_heading_level = ::Regexp.last_match(1).length if line =~ /^(\#{1,6})\s+(.*)/

        break if line.include?("{% #{@tag}") || line.include?("{%#{@tag}")
      end

      last_heading_level
    end

    def content
      @content ||= @page['content']
    end
  end
end
