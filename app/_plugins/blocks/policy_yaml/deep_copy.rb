# frozen_string_literal: true

module Jekyll
  module PolicyYaml
    module DeepCopy
      def self.call(object)
        Marshal.load(Marshal.dump(object))
      end
    end
  end
end
