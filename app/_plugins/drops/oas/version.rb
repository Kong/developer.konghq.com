# frozen_string_literal: true

module Jekyll
  module Drops
    module OAS
      class Version < Liquid::Drop
        include Comparable

        attr_reader :version_hash

        def initialize(version_hash)
          @version_hash = version_hash
        end

        def to_str
          @version_hash['name']
        end
        alias to_s to_str

        def <=>(other)
          @version_hash['name'] <=> other.version_hash['name']
        end
      end
    end
  end
end
