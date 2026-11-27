# frozen_string_literal: true

module Jekyll
  module PolicyYaml
    # Wraps rendered code in a fenced code block, optionally inside a Liquid
    # `{% raw %}` tag when the source block itself was written as raw.
    class CodeBlockFormatter
      def initialize(raw:)
        @raw = raw
      end

      def yaml(content)
        wrap("```yaml\n#{content}\n```\n")
      end

      def hcl(content)
        wrap("```hcl\n#{content}\n```\n")
      end

      private

      def wrap(block)
        return block unless @raw

        "{% raw %}\n#{block}{% endraw %}\n"
      end
    end
  end
end
