# frozen_string_literal: true

require_relative '../lib/ordered_generator'

module Jekyll
  class LandingPagesGenerator < OrderedGenerator
    def generate(site)
      Jekyll::LandingPages::Generator.run(site)
    end
  end
end
