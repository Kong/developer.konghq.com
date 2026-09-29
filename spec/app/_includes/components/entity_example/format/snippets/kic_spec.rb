# frozen_string_literal: true

RSpec.describe 'components/entity_example/format/snippets/kic.md' do
  before { stub_entity_examples_config! }

  let(:product) { 'gateway' }
  let(:drop) { Jekyll::EntityExampleBlock::Base.make_for(example: example, product: product).to_drop }

  subject(:rendered) do
    render_liquid(
      '{% include components/entity_example/format/snippets/kic.md presenter=presenter %}',
      locals: { 'presenter' => presenter }
    )
  end

  context 'consumer, plain' do
    let(:example) do
      YAML.load(<<~YAML)
        type: consumer
        data:
          username: consumer-1
          credentials:
            - consumer-1-basic-auth
        formats:
          - kic
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KIC::Base.new(example_drop: drop) }

    it 'renders a KongConsumer resource with no annotation extras' do
      expect(rendered).to eq(<<~'MD')


        ```yaml
        echo "
        apiVersion: configuration.konghq.com/v1
        kind: KongConsumer
        metadata:
          name: consumer-1
          namespace: kong
          annotations:
            kubernetes.io/ingress.class: kong
        username: consumer-1
        credentials:
        - consumer-1-basic-auth
        " | kubectl apply -f -
        ```



      MD
    end
  end

  context 'consumer, with tags' do
    let(:example) do
      YAML.load(<<~YAML)
        type: consumer
        data:
          custom_id: example-consumer-id
          username: example-consumer
          tags:
            - silver-tier
        formats:
          - kic
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KIC::Base.new(example_drop: drop) }

    it 'merges tags into the konghq.com/tags annotation' do
      expect(rendered).to eq(<<~'MD')


        ```yaml
        echo "
        apiVersion: configuration.konghq.com/v1
        kind: KongConsumer
        metadata:
          name: example-consumer
          namespace: kong
          annotations:
            kubernetes.io/ingress.class: kong
            konghq.com/tags: silver-tier
        custom_id: example-consumer-id
        username: example-consumer
        " | kubectl apply -f -
        ```



      MD
    end
  end

  context 'consumer, with plugins' do
    let(:example) do
      YAML.load(<<~YAML)
        type: consumer
        data:
          username: bob
          credentials:
            - bob-key-auth
          plugins:
            - rate-limit-consumer
        formats:
          - kic
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KIC::Base.new(example_drop: drop) }

    it 'joins plugins into the konghq.com/plugins annotation and drops the plugins key from spec' do
      expect(rendered).to eq(<<~'MD')


        ```yaml
        echo "
        apiVersion: configuration.konghq.com/v1
        kind: KongConsumer
        metadata:
          name: bob
          namespace: kong
          annotations:
            kubernetes.io/ingress.class: kong
            konghq.com/plugins: rate-limit-consumer
        username: bob
        credentials:
        - bob-key-auth
        " | kubectl apply -f -
        ```



      MD
    end
  end

  context 'vault, with a declared variable' do
    let(:example) do
      YAML.load(<<~YAML)
        type: vault
        data:
          name: hcv
          prefix: hashicorp-vault
          description: Storing secrets in HashiCorp Vault
          config:
            host: "${hcv_host}"
            token: "${hcv_token}"
            kv: v2
            mount: secret
            port: 8200
            protocol: http
        variables:
          hcv_host:
            value: vault.vault.svc.cluster.local
          hcv_token:
            value: root
        formats:
          - kic
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KIC::Base.new(example_drop: drop) }

    it 'reshapes the vault into a v1alpha1 KongVault with a spec.backend, substituting variables' do
      expect(rendered).to eq(<<~'MD')


        ```yaml
        echo "
        apiVersion: configuration.konghq.com/v1alpha1
        kind: KongVault
        metadata:
          name: hcv-vault
          namespace: kong
          annotations:
            kubernetes.io/ingress.class: kong
        spec:
          backend: hcv
          prefix: hashicorp-vault
          description: Storing secrets in HashiCorp Vault
          config:
            host: vault.vault.svc.cluster.local
            token: root
            kv: v2
            mount: secret
            port: 8200
            protocol: http
        " | kubectl apply -f -
        ```



      MD
    end
  end

  context 'plugin, global scope, with a declared variable' do
    let(:example) do
      YAML.load(<<~YAML)
        type: plugin
        data:
          name: ai-proxy
          config:
            route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: "Bearer ${key}"
            model:
              provider: openai
              name: gpt-5.1
              options:
                max_tokens: 512
                temperature: 1.0
        variables:
          key:
            value: $OPENAI_API_KEY
            description: The API key to use to connect to OpenAI.
        formats:
          - kic
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KIC::Plugin.new(example_drop: drop) }

    it 'promotes a foreign-key-less plugin to a KongClusterPlugin and substitutes the variable' do
      expect(rendered).to eq(<<~'MD')


        ```yaml
        echo "
        apiVersion: configuration.konghq.com/v1
        kind: KongClusterPlugin
        metadata:
          name: ai-proxy
          namespace: kong
          annotations:
            kubernetes.io/ingress.class: kong
          labels:
            global: 'true'
        config:
          route_type: llm/v1/chat
          auth:
            header_name: Authorization
            header_value: Bearer $OPENAI_API_KEY
          model:
            provider: openai
            name: gpt-5.1
            options:
              max_tokens: 512
              temperature: 1.0
        plugin: ai-proxy
        " | kubectl apply -f -
        ```



      MD
    end
  end

  context 'plugin, global scope, with cluster_plugin explicitly disabled' do
    let(:example) do
      YAML.load(<<~YAML)
        type: plugin
        cluster_plugin: false
        data:
          name: key-auth
          skip_annotate: true
        formats:
          - kic
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KIC::Plugin.new(example_drop: drop) }

    it 'renders a plain KongPlugin instead of promoting to KongClusterPlugin' do
      expect(rendered).to eq(<<~'MD')


        ```yaml
        echo "
        apiVersion: configuration.konghq.com/v1
        kind: KongPlugin
        metadata:
          name: key-auth
          namespace: kong
          annotations:
            kubernetes.io/ingress.class: kong
        plugin: key-auth
        " | kubectl apply -f -
        ```



      MD
    end
  end

  context 'plugin, route foreign key, with skip_annotate' do
    let(:example) do
      YAML.load(<<~YAML)
        type: plugin
        data:
          name: rate-limit-consumer
          plugin: rate-limiting
          config:
            second: 5
            policy: local
          route: route-b
          skip_annotate: true
        formats:
          - kic
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KIC::Plugin.new(example_drop: drop) }

    it 'suppresses the annotate instructions entirely' do
      expect(rendered).to eq(<<~'MD')


        ```yaml
        echo "
        apiVersion: configuration.konghq.com/v1
        kind: KongPlugin
        metadata:
          name: rate-limit-consumer
          namespace: kong
          annotations:
            kubernetes.io/ingress.class: kong
        plugin: rate-limiting
        config:
          second: 5
          policy: local
        " | kubectl apply -f -
        ```






      MD
    end
  end

  context 'plugin, service foreign key, with other_plugins' do
    let(:example) do
      YAML.load(<<~YAML)
        type: plugin
        data:
          name: basic-auth
          config:
            anonymous: anonymous
          service: echo
          other_plugins: key-auth
        formats:
          - kic
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KIC::Plugin.new(example_drop: drop) }

    it 'annotates the service, comma-joining other_plugins ahead of this plugin' do
      expect(rendered).to eq(<<~'MD')


        ```yaml
        echo "
        apiVersion: configuration.konghq.com/v1
        kind: KongPlugin
        metadata:
          name: basic-auth
          namespace: kong
          annotations:
            kubernetes.io/ingress.class: kong
        config:
          anonymous: anonymous
        plugin: basic-auth
        " | kubectl apply -f -
        ```




        Next, apply the `KongPlugin` resource by annotating the `service` resource:


        ```bash
        kubectl annotate -n kong service echo konghq.com/plugins=key-auth,basic-auth --overwrite
        ```




      MD
    end
  end

  context 'plugin, consumer foreign key' do
    let(:example) do
      YAML.load(<<~YAML)
        type: plugin
        data:
          name: request-termination
          config:
            message: "Authentication required"
            status_code: 401
          consumer: anonymous
        formats:
          - kic
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KIC::Plugin.new(example_drop: drop) }

    it 'annotates the KongConsumer resource using the kongconsumer resource name' do
      expect(rendered).to eq(<<~'MD')


        ```yaml
        echo "
        apiVersion: configuration.konghq.com/v1
        kind: KongPlugin
        metadata:
          name: request-termination
          namespace: kong
          annotations:
            kubernetes.io/ingress.class: kong
        config:
          message: Authentication required
          status_code: 401
        plugin: request-termination
        " | kubectl apply -f -
        ```




        Next, apply the `KongPlugin` resource by annotating the `KongConsumer` resource:


        ```bash
        kubectl annotate -n kong kongconsumer anonymous konghq.com/plugins=request-termination
        ```




      MD
    end
  end

  context 'route (custom template override)' do
    let(:example) do
      YAML.load(<<~YAML)
        type: route
        data:
          name: example-route
          host: "*.tls-example.com"
          protocols:
            - https
            - tls
          paths:
            - /mock
          snis:
            - my-sni
        formats:
          - kic
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KIC::Base.new(example_drop: drop) }

    it 'defers to the route-specific HTTPRoute snippet instead of the generic resource' do
      expect(rendered).to eq(<<~MD)

        Routes are defined using native Kubernetes resources such as `Ingress` and `HTTPRoute`. This example uses HTTPRoute, but you can also use `Ingress` if needed. See the [Kong Ingress Controller](/kubernetes-ingress-controller/routing/http/) documentation for Ingress docs.

        To create a route in Kong Gateway, create an `HTTPRoute` resource that points to a service in your cluster:

        ```yaml
        apiVersion: gateway.networking.k8s.io/v1
        kind: HTTPRoute
        metadata:
          name: example-route
          annotations:
            konghq.com/strip-path: 'true'
        spec:
          parentRefs:
          - name: kong
          rules:
          - matches:
            - path:
                type: PathPrefix
                value: /mock
            backendRefs:
            - name: example-route-demo-service
              kind: Service
              port: 1027
        ```




      MD
    end
  end

  context 'service (custom template override)' do
    let(:example) do
      YAML.load(<<~YAML)
        type: service
        data:
          name: example-service
          url: "http://httpbin.konghq.com"
        formats:
          - kic
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KIC::Base.new(example_drop: drop) }

    it 'defers to the service-specific snippet explaining services are not managed directly' do
      expect(rendered).to eq(<<~MD)

        Kong Ingress Controller doesn't manage Services directly. Any Kubernetes resources referenced by an `Ingress` or Gateway API `*Route` resource will automatically be created.

        Create a [Route](/gateway/entities/route/?tab=kic#setup-entity) to get started.




      MD
    end
  end

  context 'consumer group (custom template override)' do
    let(:example) do
      YAML.load(<<~YAML)
        type: consumer_group
        data:
          name: my_group
        formats:
          - kic
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KIC::Base.new(example_drop: drop) }

    it 'defers to the consumer-group-specific KongConsumerGroup snippet' do
      expect(rendered).to eq(<<~'MD')

        ```yaml
        apiVersion: configuration.konghq.com/v1
        kind: KongConsumerGroup
        metadata:
          name: { { include.presenter.data.name } }
          annotations:
            kubernetes.io/ingress.class: kong
        ```




      MD
    end
  end

  context 'target (custom template override)' do
    let(:example) do
      YAML.load(<<~YAML)
        type: target
        data:
          target: httpbun.com:80
          weight: 100
        formats:
          - kic
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KIC::Base.new(example_drop: drop) }

    it 'defers to the target-specific snippet explaining targets are auto-discovered' do
      expect(rendered).to eq(<<~MD)

        Kong Ingress Controller automatically configures your Target based on the endpoints discovered in your Kubernetes cluster.




      MD
    end
  end

  context 'upstream (custom template override)' do
    let(:example) do
      YAML.load(<<~YAML)
        type: upstream
        data:
          name: example-upstream
          algorithm: round-robin
        formats:
          - kic
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KIC::Base.new(example_drop: drop) }

    it 'defers to the upstream-specific snippet explaining upstreams are auto-discovered' do
      expect(rendered).to eq(<<~MD)

        Kong Ingress Controller automatically configures your Upstream based on the endpoints discovered in your Kubernetes cluster.




      MD
    end
  end
end
