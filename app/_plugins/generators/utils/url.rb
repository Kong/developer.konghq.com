# frozen_string_literal: true

module Jekyll
  module Utils
    class URL
      def self.normalize_path(path)
        path.dup.prepend('/').concat('/').gsub(%r{\/+}, '/')
      end
    end
  end
end