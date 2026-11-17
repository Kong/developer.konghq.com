# frozen_string_literal: true

module Jekyll
  class FeedsGenerator < Jekyll::Generator # rubocop:disable Style/Documentation
    priority :low

    def generate(site)
      Jekyll::Feeds::Generator.run(site)
    end
  end
end
