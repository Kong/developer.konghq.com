module Jekyll
  module CustomFilters
    def markdown(input)
      r = @context.registers[:site].find_converter_instance(
        Jekyll::Converters::Markdown
      ).convert(input.to_s)

      # Remove the outer paragraph tag that markdown converter adds
      r.sub(/<p>/, '').sub(/<\/p>/, '')
    end
  end
end

Liquid::Template.register_filter(
  Jekyll::CustomFilters
)