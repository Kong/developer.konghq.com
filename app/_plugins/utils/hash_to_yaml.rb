# frozen_string_literal: true

require 'yaml'

module Jekyll
  module Utils
    class HashToYAML
      def self.run(hash)
        YAML.dump(hash).delete_prefix("---\n")
      end
    end
  end
end
