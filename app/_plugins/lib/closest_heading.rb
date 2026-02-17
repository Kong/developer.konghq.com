# frozen_string_literal: true

module Jekyll
  class ClosestHeading # rubocop:disable Style/Documentation
    def initialize(page, line_number, context)
      @page = page
      @line_number = line_number
      @context = context
    end

    def closest_heading
      return 2 if @line_number.nil?

      # Scan backwards from the tag's line
      heading = lines[0...@line_number - 1]
                .reverse
                .find { |line| line.match?(/^\#{1,6}\s+/) }

      return 2 unless heading

      match = heading.match(/^(\#{1,6})\s+(.*)/)
      match[1].length
    end

    def level
      closest = closest_heading
      current_level = closest || @context['heading_level'] || 2

      current_level += 1
      current_level += 1 if @context['tab_id']
      current_level
    end

    private

    def site
      @site ||= @context.registers[:site]
    end

    def lines
      @lines ||= if @context.registers[:current_include_path]
                   File.readlines(@context.registers[:current_include_path])
                 else
                   @page['content'].lines
                 end
    end
  end
end
