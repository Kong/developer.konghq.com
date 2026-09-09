# frozen_string_literal: true

module Jekyll
  module PolicyYaml
    # Runs every parsed YAML document through the NodeProcessor for each Style,
    # concatenating multi-document output and collecting the Terraform rendering.
    class StyleRenderer
      def initialize(node_processor:, namespace:)
        @node_processor = node_processor
        @namespace = namespace
        @styles = styles
      end

      def render(documents)
        contents = Hash.new { |hash, key| hash[key] = '' }
        terraform_content = +''

        documents.each do |document|
          @styles.each do |style|
            processed = @node_processor.process(DeepCopy.call(document), style.context)
            append!(contents, style.name, processed)
            terraform_content << TerraformRenderer.new(processed).render if style.name == :uni
          end
        end

        [contents, terraform_content]
      end

      private

      def append!(contents, name, processed)
        contents[name] += "\n---\n" unless contents[name].empty?
        contents[name] += dump(processed)
      end

      def dump(processed)
        YAML.dump(processed).gsub(/^---\n/, '').chomp
      end

      def styles
        [
          Style.new(name: :uni_legacy, env: :universal, legacy_output: true, namespace: nil),
          Style.new(name: :uni, env: :universal, legacy_output: false, namespace: nil),
          Style.new(name: :kube_legacy, env: :kubernetes, legacy_output: true, namespace: @namespace),
          Style.new(name: :kube, env: :kubernetes, legacy_output: false, namespace: @namespace)
        ]
      end
    end
  end
end
