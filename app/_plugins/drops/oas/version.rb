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

        def name
          @name ||= @version_hash['name']
        end

        def id
          @id ||= @version_hash['id']
        end

        def to_str
          value
        end
        alias to_s to_str

        def <=>(other)
          @version_hash['name'] <=> other.version_hash['name']
        end

        private

        def value
          @value ||= if Gem::Version.correct?(name)
                       if name.match?(/^\d+\.\d+\.\d+\.\d+$/)
                         name.sub(/^(\d+\.\d+)\.\d+\.\d+$/, '\1')
                       else
                         name.sub(/^(\d+\.\d+)\.\d+$/, '\1')
                       end
                     else
                       name
                     end
        end
      end
    end
  end
end
