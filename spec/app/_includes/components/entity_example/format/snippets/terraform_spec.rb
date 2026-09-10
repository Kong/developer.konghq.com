# frozen_string_literal: true

RSpec.describe 'components/entity_example/format/snippets/terraform.md' do
  before { stub_entity_examples_config! }

  let(:drop) { Jekyll::EntityExampleBlock::Base.make_for(example: example, product: product).to_drop }

  subject(:rendered) do
    render_liquid(
      '{% include components/entity_example/format/snippets/terraform.md presenter=presenter %}',
      locals: { 'presenter' => presenter }
    )
  end

  context 'plugin type, global scope, with two declared variables' do
    let(:product) { 'gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: plugin
        data:
          name: ai-proxy
          config:
            route_type: llm/v1/chat
            auth:
              allow_override: false
              aws_access_key_id: "${key}"
              aws_secret_access_key: "${secret}"
            model:
              provider: bedrock
              name: meta.llama3-70b-instruct-v1:0
              options:
                bedrock:
                  aws_region: us-east-1
        variables:
          key:
            value: $AWS_ACCESS_KEY_ID
            description: The AWS access key ID to use to connect to Bedrock.
          secret:
            value: $AWS_SECRET_ACCESS_KEY
            description: The AWS secret access key to use to connect to Bedrock.
        formats:
          - terraform
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::Terraform::Plugin.new(example_drop: drop) }

    it 'declares a variable block for every declared variable, not just the last one' do
      expect(rendered).to eq(<<~'MD')


        ```hcl
        resource "konnect_gateway_plugin_ai_proxy" "my_ai_proxy" {
          enabled = true

          config = {
            route_type = "llm/v1/chat"

            auth = {
              allow_override = false
              aws_access_key_id = var.aws_access_key_id
              aws_secret_access_key = var.aws_secret_access_key
            }

            model = {
              provider = "bedrock"
              name = "meta.llama3-70b-instruct-v1:0"

              options = {

                bedrock = {
                  aws_region = "us-east-1"
                }
              }
            }
          }

          control_plane_id = konnect_gateway_control_plane.my_konnect_cp.id
        }
        ```




        This example requires the following variables to be added to your manifest. You can specify values at runtime by setting `TF_VAR_name=value`.

        ```
        variable "aws_access_key_id" {
          type = string
        }
        variable "aws_secret_access_key" {
          type = string
        }
        ```
      MD
    end
  end

  context 'plugin type, global scope, no variables' do
    let(:product) { 'gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: plugin
        data:
          name: rate-limiting
          config:
            minute: 5
            policy: local
            limit_by: ip
          ordering:
            before:
              access:
                - key-auth
        formats:
          - terraform
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::Terraform::Plugin.new(example_drop: drop) }

    it 'renders a global plugin resource including its ordering array' do
      expect(rendered).to eq(<<~'MD')


        ```hcl
        resource "konnect_gateway_plugin_rate_limiting" "my_rate_limiting" {
          enabled = true

          config = {
            minute = 5
            policy = "local"
            limit_by = "ip"
          }
          ordering = {

            before = {
              access = ["key-auth"]
            }
          }

          control_plane_id = konnect_gateway_control_plane.my_konnect_cp.id
        }
        ```


      MD
    end
  end

  context 'plugin type, global scope, with one declared variable' do
    let(:product) { 'gateway' }
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
          - terraform
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::Terraform::Plugin.new(example_drop: drop) }

    it 'substitutes the variable as an unquoted var. reference and declares one variable block' do
      expect(rendered).to eq(<<~'MD')


        ```hcl
        resource "konnect_gateway_plugin_ai_proxy" "my_ai_proxy" {
          enabled = true

          config = {
            route_type = "llm/v1/chat"

            auth = {
              header_name = "Authorization"
              header_value = "Bearer var.openai_api_key"
            }

            model = {
              provider = "openai"
              name = "gpt-5.1"

              options = {
                max_tokens = 512
                temperature = 1.0
              }
            }
          }

          control_plane_id = konnect_gateway_control_plane.my_konnect_cp.id
        }
        ```




        This example requires the following variables to be added to your manifest. You can specify values at runtime by setting `TF_VAR_name=value`.

        ```
        variable "openai_api_key" {
          type = string
        }
        ```
      MD
    end
  end

  context 'target type' do
    let(:product) { 'gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: target
        data:
          target: httpbun.com:80
          weight: 100
        formats:
          - terraform
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::Terraform::Base.new(example_drop: drop) }

    it 'wires the target to an upstream_id reference' do
      expect(rendered).to eq(<<~'MD')

        ```hcl
        resource "konnect_gateway_target" "my_target" {
          target = "httpbun.com:80"
          weight = 100

          upstream_id = konnect_gateway_upstream.my_upstream.id
          control_plane_id = konnect_gateway_control_plane.my_konnect_cp.id
        }
        ```


      MD
    end
  end

  context 'vault type, with one declared variable' do
    let(:product) { 'gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: vault
        data:
          name: konnect
          prefix: mysecretvault
          description: Storing secrets in Konnect
          config:
            config_store_id: "${config-store-id}"
        variables:
          config-store-id:
            value: $CONFIG_STORE_ID
        formats:
          - terraform
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::Terraform::Base.new(example_drop: drop) }

    it 'falls through to the generic gateway resource branch and declares a variable block' do
      expect(rendered).to eq(<<~'MD')


        ```hcl
        resource "konnect_gateway_vault" "my_vault" {
          prefix = "mysecretvault"
          description = "Storing secrets in Konnect"
          config = {
            config_store_id = var.config_store_id
          }

          control_plane_id = konnect_gateway_control_plane.my_konnect_cp.id
        }
        ```





        This example requires the following variables to be added to your manifest. You can specify values at runtime by setting `TF_VAR_name=value`.

        ```
        variable "config_store_id" {
          type = string
        }
        ```
      MD
    end
  end

  context 'ca_certificate type, with a multi-line certificate value' do
    let(:product) { 'gateway' }
    let(:example) do
      YAML.load(<<~'YAML')
        type: ca_certificate
        data:
          cert: |
            -----BEGIN CERTIFICATE-----
            MIIB4TCCAYugAwIBAgIUAenxUyPjkSLCe2BQXoBMBacqgLowDQYJKoZIhvcNAQEL
            BQAwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoM
            qKjBs0k=
            -----END CERTIFICATE-----
        formats:
          - terraform
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::Terraform::Base.new(example_drop: drop) }

    it 'renders the multi-line value as a heredoc instead of a quoted string' do
      expect(rendered).to eq(<<~'MD')


        ```hcl
        resource "konnect_gateway_ca_certificate" "my_ca_certificate" {
          cert = <<EOF
        -----BEGIN CERTIFICATE-----
        MIIB4TCCAYugAwIBAgIUAenxUyPjkSLCe2BQXoBMBacqgLowDQYJKoZIhvcNAQEL
        BQAwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoM
        qKjBs0k=
        -----END CERTIFICATE-----
        EOF

          control_plane_id = konnect_gateway_control_plane.my_konnect_cp.id
        }
        ```



      MD
    end
  end

  context 'event_gateway_policy type, listener-targeted' do
    before do
      config = YAML.load_file(File.join(PROJECT_ROOT, 'app/_data/entity_examples/config.yml'), aliases: true)
      site = instance_double(
        Jekyll::Site,
        data: {
          'entity_examples' => { 'config' => config },
          'event_gateway_policies' => {
            'forward-to-virtual-cluster' => instance_double(Jekyll::Page, data: { 'policy_target' => 'listener' })
          }
        }
      )
      allow(Jekyll).to receive(:sites).and_return([site])
    end

    let(:product) { 'event-gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: event_gateway_policy
        policy_type: forward-to-virtual-cluster
        name: forward
        data:
          advertised_host: 0.0.0.0
          bootstrap_port: at_start
          destination:
            name: example-virtual-cluster
          min_broker_id: 1
          type: port_mapping
        formats:
          - terraform
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::Terraform::EventGatewayPolicy.new(example_drop: drop) }

    it 'names the resource with the listener policy suffix and wires an event_gateway_listener_id' do
      expect(rendered).to eq(<<~'MD')


        ```hcl
        resource "konnect_event_gateway_listener_policy_forward_to_virtual_cluster" "my_listener_policy_forward_to_virtual_cluster" {
          provider = konnect-beta
          type = "forward-to-virtual-cluster"
          config = {
            advertised_host = "0.0.0.0"
            bootstrap_port = "at_start"

            destination = {
              name = "example-virtual-cluster"
            }
            min_broker_id = 1
            type = "port_mapping"
          }


          event_gateway_listener_id = konnect_event_gateway_listener.my_listener.id

          gateway_id = konnect_event_gateway.my_event_gateway.id
        }
        ```



      MD
    end
  end

  context 'event_gateway_policy type, phase-targeted' do
    before do
      config = YAML.load_file(File.join(PROJECT_ROOT, 'app/_data/entity_examples/config.yml'), aliases: true)
      site = instance_double(
        Jekyll::Site,
        data: {
          'entity_examples' => { 'config' => config },
          'event_gateway_policies' => {
            'modify-headers' => instance_double(Jekyll::Page, data: { 'policy_target' => 'virtual_cluster' })
          }
        }
      )
      allow(Jekyll).to receive(:sites).and_return([site])
    end

    let(:product) { 'event-gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: event_gateway_policy
        policy_type: modify-headers
        phase: consume
        name: new-header
        data:
          actions:
            - op: set
              key: My-New-Header
              value: header_value
        formats:
          - terraform
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::Terraform::EventGatewayPolicy.new(example_drop: drop) }

    it 'names the resource with the phase and wires a virtual_cluster_id' do
      expect(rendered).to eq(<<~'MD')


        ```hcl
        resource "konnect_event_gateway_consume_policy_modify_headers" "my_virtual_cluster_policy_modify_headers" {
          provider = konnect-beta
          type = "modify-headers"
          config = {
            actions = [
              {
                op = "set"
                key = "My-New-Header"
                value = "header_value"
              }    ]
          }


          virtual_cluster_id = konnect_event_gateway_virtual_cluster.my_virtual_cluster.id

          gateway_id = konnect_event_gateway.my_event_gateway.id
        }
        ```



      MD
    end
  end

  context 'backend_cluster type, event-gateway product, no policy' do
    let(:product) { 'event-gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: backend_cluster
        data:
          name: example-backend-cluster
          bootstrap_servers:
            - "host:9092"
          authentication:
            type: anonymous
          insecure_allow_anonymous_virtual_cluster_auth: true
          tls:
            insecure_skip_verify: false
        formats:
          - terraform
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::Terraform::Base.new(example_drop: drop) }

    it 'renders the generic event-gateway resource with no listener or virtual_cluster id' do
      expect(rendered).to eq(<<~'MD')


        ```hcl
        resource "konnect_event_gateway_backend_cluster" "my_backend_cluster" {
          provider = konnect-beta
          bootstrap_servers = ["host:9092"]
          authentication = {
            type = "anonymous"
          }
          insecure_allow_anonymous_virtual_cluster_auth = true
          tls = {
            insecure_skip_verify = false
          }



          gateway_id = konnect_event_gateway.my_event_gateway.id
        }
        ```



      MD
    end
  end

  context 'partial type, with declared variables' do
    let(:product) { 'gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: partial
        data:
          name: shared-vectordb
          type: vectordb
          config:
            strategy: pgvector
            dimensions: 1536
            distance_metric: cosine
            pgvector:
              host: "${pgvector_host}"
              port: 5432
              database: kong-pgvector
              user: postgres
              password: "${pgvector_password}"
        variables:
          pgvector_host:
            value: $PGVECTOR_HOST
            description: The hostname of your pgvector database.
          pgvector_password:
            value: $PGVECTOR_PASSWORD
            description: The password for your pgvector database.
        formats:
          - terraform
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::Terraform::Base.new(example_drop: drop) }

    it 'substitutes variables into var. references and declares a variable block for each one' do
      expect(rendered).to eq(<<~'MD')


        ```hcl
        resource "konnect_gateway_partial" "my_partial" {
          type = "vectordb"
          config = {
            strategy = "pgvector"
            dimensions = 1536
            distance_metric = "cosine"

            pgvector = {
              host = var.pgvector_host
              port = 5432
              database = "kong-pgvector"
              user = "postgres"
              password = var.pgvector_password
            }
          }

          control_plane_id = konnect_gateway_control_plane.my_konnect_cp.id
        }
        ```





        This example requires the following variables to be added to your manifest. You can specify values at runtime by setting `TF_VAR_name=value`.

        ```
        variable "pgvector_host" {
          type = string
        }
        variable "pgvector_password" {
          type = string
        }
        ```
      MD
    end
  end
end
