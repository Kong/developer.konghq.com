# frozen_string_literal: true

module Jekyll
  class OperatorPodtemplatespecExample < Liquid::Block
    def render(context)
      spec = super

      begin
        config = YAML.safe_load(spec)
      rescue Psych::SyntaxError => e
        raise "Unable to parse config in operator_podtemplatespec_example: \n#{spec}\n\n#{e}"
      end

      dp = config['dataplane'].to_yaml.split("\n")[1..].join("\n")

      <<~TEXT
        #{dataplane_example(dp, config['kubectl_apply']) if config['dataplane']}#{' '}
      TEXT
    end

    private

    def dataplane_example(spec, kubectl_apply) # rubocop:disable Metrics/MethodLength
      return '' if spec.empty?

      <<~TEXT
        {:.info}
        > The the following example uses the `DataPlane` resource, but you can also configure your `GatewayConfiguration` resource as needed. For more information see the [PodTemplateSpec](/operator/dataplanes/reference/podtemplatespec/) page.

        ```yaml
        #{kubectl_apply && "echo '"}
        apiVersion: gateway-operator.konghq.com/v1beta1
        kind: DataPlane
        metadata:
          name: dataplane-example
          namespace: kong
        spec:
          deployment:
            podTemplateSpec:
              #{spec.split("\n").map { |line| "      #{line}" }.join("\n").strip}
        #{kubectl_apply && "' | kubectl apply -f -"}
        ```
      TEXT
    end
  end
end

Liquid::Template.register_tag('operator_podtemplatespec_example', Jekyll::OperatorPodtemplatespecExample)
