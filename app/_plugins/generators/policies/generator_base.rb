# frozen_string_literal: true

module Jekyll
  module Policies
    module GeneratorBase # rubocop:disable Style/Documentation
      def policy_class
        "#{namespace}::Policy".constantize
      end

      def overview_page_class
        "#{namespace}::Pages::Overview".constantize
      end

      def reference_page_class
        "#{namespace}::Pages::Reference".constantize
      end

      def example_page_class
        "#{namespace}::Pages::Example".constantize
      end

      def namespace
        self.class.name.deconstantize
      end
    end
  end
end
