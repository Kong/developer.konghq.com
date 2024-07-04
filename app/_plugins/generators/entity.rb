# frozen_string_literal: true

module Jekyll
  class EntityGenerator < Jekyll::Generator
    priority :low

    def generate(site)
      Jekyll::KongEntity::Generator.run(site)
    end
  end
end
