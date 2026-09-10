# frozen_string_literal: true

module Jekyll
  module FileCache
    @cache = {}

    def self.read(path)
      @cache[path] ||= File.read(path)
    end
  end
end
