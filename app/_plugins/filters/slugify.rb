# frozen_string_literal: true

module Jekyll
  module SlugifyFilter
    def slugify(input)
      if input.is_a? String
        input.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
      else
        raise "Invalid input type: #{input.class} to 'slugify'. Input must be a string."
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::SlugifyFilter)
