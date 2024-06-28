# frozen_string_literal: true

module Jekyll
  class LandingPagesGenerator < Jekyll::Generator
    priority :low

    def generate(site)
      Jekyll::LandingPages::Generator.run(site)
    end
  end
end
