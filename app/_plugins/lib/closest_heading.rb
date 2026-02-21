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

      p "Closest heading: #{match[2].strip} (level #{match[1].length})"
      match[1].length
    end

    def level
      closest = closest_heading
      current_level = closest || @context['heading_level'] || 2

      current_level += 1
      current_level += 1 if @context['tab_id']
      current_level

      # last_heading_level = 1
      # last_heading = ''
      # content.lines.each do |line|
      #  if line =~ /^(\#{1,6})\s+(.*)/
      #    last_heading_level = ::Regexp.last_match(1).length
      #    last_heading = ::Regexp.last_match(2).strip
      #  end
      #
      #  break if line.include?("{% #{@tag}") || line.include?("{%#{@tag}")
      # end
      #
      # p "#{last_heading_level} - #{last_heading}"
      # level = if current_level.to_i > 0
      #          current_level.to_i + 1
      #        else
      #          last_heading_level
      #        end
      #
      # level += 1 if @context['tab_id']
      # level
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
