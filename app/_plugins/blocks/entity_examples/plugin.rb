# frozen_string_literal: true

require_relative './base'

module Jekyll
  module EntityExamples
    class Plugin < Base
      def targets
        @targets ||= @example.fetch('targets').map do |t|
          Jekyll::EntityExamples::Target::Base.make_for(target: t)
        end
      end

      def validate!
        super

        raise ArgumentError, "Missing `targets` for entity_type `plugin`. Available targets: #{Target::Base::MAPPINGS.keys.join(', ')}." unless @example['targets']

        targets.map(&:validate!)
      end
    end
  end
end
