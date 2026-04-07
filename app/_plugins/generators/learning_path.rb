# frozen_string_literal: true

require_relative 'learning_path/generator'

module Jekyll
  class LearningPathGenerator < Jekyll::Generator
    priority :high

    def generate(site)
      Jekyll::LearningPath::Generator.run(site)
    end
  end
end
