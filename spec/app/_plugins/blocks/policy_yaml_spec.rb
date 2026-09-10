# frozen_string_literal: true

require 'yaml'

RSpec.describe Jekyll::RenderPolicyYaml do
  let(:locals) { {} }

  def release(number)
    Jekyll::Drops::Release.new('release' => number)
  end

  def page_with(release_number)
    { 'output_format' => 'html', 'path' => 'test.md', 'content' => '', 'release' => release(release_number) }
  end

  def render(template, release_number: '2.10')
    Capybara::Node::Simple.new(render_liquid(template, page: page_with(release_number), locals: locals))
  end

  def tab_titles(html)
    html.all('button[role="tab"]').map { |b| b.text.strip }
  end

  def yaml_text(html, panel, index: 0)
    html.find("div[data-panel=\"#{panel}\"]").all('code')[index].text
  end

  def yaml_docs(html, panel, index: 0)
    YAML.load_stream(yaml_text(html, panel, index: index))
  end

  describe 'default rendering (no params)' do
    let(:template) do
      <<~LIQUID
        {% policy_yaml %}
        ```yaml
        type: MeshTrafficPermission
        mesh: default
        name: mtp-mesh-to-mesh
        spec:
          targetRef:
            kind: MeshSubset
            tags:
              customTag: true
          from:
            - targetRef:
                kind: Mesh
              default:
                action: Allow
        ```
        {% endpolicy_yaml %}
      LIQUID
    end

    it 'renders a Kubernetes tab and a Universal tab' do
      expect(tab_titles(render(template, release_number: '2.9'))).to eq(%w[Kubernetes Universal])
    end

    it 'wraps the type and name into apiVersion/kind/metadata for Kubernetes' do
      expect(yaml_text(render(template), 'kubernetes')).to eq(<<~YAML.strip)
        apiVersion: kuma.io/v1alpha1
        kind: MeshTrafficPermission
        metadata:
          name: mtp-mesh-to-mesh
          namespace: kong-mesh-system
          labels:
            kuma.io/mesh: default
        spec:
          targetRef:
            kind: MeshSubset
            tags:
              customTag: true
          from:
          - targetRef:
              kind: Mesh
            default:
              action: Allow
      YAML
    end

    it 'keeps the universal document as the raw type/mesh/name shape' do
      expect(yaml_text(render(template), 'universal')).to eq(<<~YAML.strip)
        type: MeshTrafficPermission
        mesh: default
        name: mtp-mesh-to-mesh
        spec:
          targetRef:
            kind: MeshSubset
            tags:
              customTag: true
          from:
          - targetRef:
              kind: Mesh
            default:
              action: Allow
      YAML
    end

    it 'does not render a Terraform tab when the release predates 2.10' do
      html = render(template, release_number: '2.9')
      expect(tab_titles(html)).to eq(%w[Kubernetes Universal])
      expect(html).not_to have_css('div[data-panel="terraform"]')
    end

    it 'renders a Terraform tab when the release is at least 2.10' do
      html = render(template)
      expect(tab_titles(html)).to eq(%w[Kubernetes Universal Terraform])
      expect(html.find('div[data-panel="terraform"]').find('code').text).to eq(<<~HCL)
        resource "konnect_mesh_traffic_permission" "mtp_mesh_to_mesh" {
          provider = konnect-beta
          type = "MeshTrafficPermission"
          name = "mtp-mesh-to-mesh"
          spec = {
            target_ref = {
              kind = "MeshSubset"
              tags = {
                custom_tag = "true"
              }
            }
            from = [
              {
                target_ref = {
                  kind = "Mesh"
                }
                default = {
                  action = "Allow"
                }
              }
            ]
          }
          labels   = {
          "kuma.io/mesh" = konnect_mesh.my_mesh.name
          }
          cp_id    = konnect_mesh_control_plane.my_meshcontrolplane.id
          mesh     = konnect_mesh.my_mesh.name
        }
      HCL
    end
  end

  describe 'namespace= param' do
    let(:template) do
      <<~LIQUID
        {% policy_yaml namespace=kong-mesh-demo %}
        ```yaml
        type: MeshService
        name: redis
        mesh: default
        spec:
          selector:
            dataplaneTags:
              app: redis
        ```
        {% endpolicy_yaml %}
      LIQUID
    end

    it 'sets the Kubernetes metadata namespace' do
      expect(yaml_text(render(template), 'kubernetes')).to eq(<<~YAML.strip)
        apiVersion: kuma.io/v1alpha1
        kind: MeshService
        metadata:
          name: redis
          namespace: kong-mesh-demo
          labels:
            kuma.io/mesh: default
        spec:
          selector:
            dataplaneTags:
              app: redis
      YAML
    end

    it 'does not add a namespace field to the Universal document' do
      expect(yaml_text(render(template), 'universal')).to eq(<<~YAML.strip)
        type: MeshService
        name: redis
        mesh: default
        spec:
          selector:
            dataplaneTags:
              app: redis
      YAML
    end
  end

  describe 'use_meshservice= param (MeshService backendRefs with weight)' do
    let(:template) do
      <<~LIQUID
        {% policy_yaml use_meshservice=true %}
        ```yaml
        type: MeshTCPRoute
        name: tcp-route
        mesh: default
        spec:
          targetRef:
            kind: MeshGateway
            name: edge-gateway
          to:
            - targetRef:
                kind: Mesh
              rules:
                - default:
                    backendRefs:
                      - kind: MeshService
                        name: example-v1
                        namespace: app
                        port: 8080
                        weight: 90
                      - kind: MeshService
                        name: example-v2
                        namespace: app
                        port: 8080
                        weight: 10
        ```
        {% endpolicy_yaml %}
      LIQUID
    end

    context 'when the release is at least 2.9' do
      it 'shows the MeshService opt-in checkbox' do
        expect(render(template)).to have_css('.meshservice input.checkbox')
      end

      it 'renders a legacy tag-based backendRef for Kubernetes' do
        expect(yaml_text(render(template), 'kubernetes', index: 0)).to eq(<<~YAML.strip)
          apiVersion: kuma.io/v1alpha1
          kind: MeshTCPRoute
          metadata:
            name: tcp-route
            namespace: kong-mesh-system
            labels:
              kuma.io/mesh: default
          spec:
            targetRef:
              kind: MeshGateway
              name: edge-gateway
            to:
            - targetRef:
                kind: Mesh
              rules:
              - default:
                  backendRefs:
                  - kind: MeshService
                    name: example-v1_app_svc_8080
                    weight: 90
                  - kind: MeshService
                    name: example-v2_app_svc_8080
                    weight: 10
        YAML
      end

      it 'renders a MeshService backendRef for Kubernetes' do
        expect(yaml_text(render(template), 'kubernetes', index: 1)).to eq(<<~YAML.strip)
          apiVersion: kuma.io/v1alpha1
          kind: MeshTCPRoute
          metadata:
            name: tcp-route
            namespace: kong-mesh-system
            labels:
              kuma.io/mesh: default
          spec:
            targetRef:
              kind: MeshGateway
              name: edge-gateway
            to:
            - targetRef:
                kind: Mesh
              rules:
              - default:
                  backendRefs:
                  - kind: MeshService
                    name: example-v1
                    namespace: app
                    port: 8080
                    weight: 90
                  - kind: MeshService
                    name: example-v2
                    namespace: app
                    port: 8080
                    weight: 10
        YAML
      end

      it 'renders a legacy tag-based backendRef for Universal' do
        expect(yaml_text(render(template), 'universal', index: 0)).to eq(<<~YAML.strip)
          type: MeshTCPRoute
          name: tcp-route
          mesh: default
          spec:
            targetRef:
              kind: MeshGateway
              name: edge-gateway
            to:
            - targetRef:
                kind: Mesh
              rules:
              - default:
                  backendRefs:
                  - kind: MeshService
                    name: example-v1
                    weight: 90
                  - kind: MeshService
                    name: example-v2
                    weight: 10
        YAML
      end

      it 'renders a MeshService backendRef for Universal' do
        expect(yaml_text(render(template), 'universal', index: 1)).to eq(<<~YAML.strip)
          type: MeshTCPRoute
          name: tcp-route
          mesh: default
          spec:
            targetRef:
              kind: MeshGateway
              name: edge-gateway
            to:
            - targetRef:
                kind: Mesh
              rules:
              - default:
                  backendRefs:
                  - kind: MeshService
                    name: example-v1
                    port: 8080
                    weight: 90
                  - kind: MeshService
                    name: example-v2
                    port: 8080
                    weight: 10
        YAML
      end

      it 'derives the Terraform resource from the Universal, non-legacy rendering (no namespace field)' do
        tf = render(template).find('div[data-panel="terraform"]').find('code').text
        expect(tf).to eq(<<~HCL)
          resource "konnect_mesh_tcp_route" "tcp_route" {
            provider = konnect-beta
            type = "MeshTCPRoute"
            name = "tcp-route"
            spec = {
              target_ref = {
                kind = "MeshGateway"
                name = "edge-gateway"
              }
              to = [
                {
                  target_ref = {
                    kind = "Mesh"
                  }
                  rules = [
                    {
                      default = {
                        backend_refs = [
                          {
                            kind = "MeshService"
                            name = "example-v1"
                            port = "8080"
                            weight = "90"
                          },
                          {
                            kind = "MeshService"
                            name = "example-v2"
                            port = "8080"
                            weight = "10"
                          }
                        ]
                      }
                    }
                  ]
                }
              ]
            }
            labels   = {
            "kuma.io/mesh" = konnect_mesh.my_mesh.name
            }
            cp_id    = konnect_mesh_control_plane.my_meshcontrolplane.id
            mesh     = konnect_mesh.my_mesh.name
          }
        HCL
      end
    end

    context 'when the release predates 2.9' do
      it 'does not show the MeshService opt-in checkbox' do
        expect(render(template, release_number: '2.8')).not_to have_css('.meshservice')
      end

      it 'renders only the legacy tag-based backendRef for Kubernetes' do
        html = render(template, release_number: '2.8')
        expect(html.find('div[data-panel="kubernetes"]').all('code').length).to eq(1)
      end
    end
  end

  describe 'tools= param' do
    let(:template) do
      <<~LIQUID
        {% policy_yaml tools=kubernetes %}
        ```yaml
        type: MeshTrafficPermission
        mesh: default
        name: p
        spec:
          targetRef:
            kind: Mesh
        ```
        {% endpolicy_yaml %}
      LIQUID
    end

    it 'restricts rendering to the requested tab only' do
      expect(tab_titles(render(template))).to eq(['Kubernetes'])
    end
  end

  describe 'dot-path param resolution (as used by _includes/mesh_policies/example.md)' do
    let(:template) do
      <<~LIQUID
        {% policy_yaml namespace=page.example.namespace use_meshservice=page.example.use_meshservice tools=page.example.tools %}
        ```yaml
        type: MeshTrafficPermission
        mesh: default
        name: p
        spec:
          targetRef:
            kind: Mesh
        ```
        {% endpolicy_yaml %}
      LIQUID
    end

    let(:page) do
      page_with('2.10').merge(
        'example' => { 'namespace' => 'resolved-namespace', 'use_meshservice' => false, 'tools' => %w[universal] }
      )
    end

    it 'resolves namespace from the page data rather than treating it as a literal string' do
      html = Capybara::Node::Simple.new(render_liquid(template, page: page, locals: locals))
      expect(yaml_text(html, 'universal')).to eq(<<~YAML.strip)
        type: MeshTrafficPermission
        mesh: default
        name: p
        spec:
          targetRef:
            kind: Mesh
      YAML
    end

    it 'resolves tools from the page data to restrict the rendered tabs' do
      html = Capybara::Node::Simple.new(render_liquid(template, page: page, locals: locals))
      expect(tab_titles(html)).to eq(['Universal'])
    end
  end

  describe 'multi-document YAML body (as used by mesh-multi-tenancy.md)' do
    let(:template) do
      <<~LIQUID
        {% policy_yaml %}
        ```yaml
        type: MeshRetry
        mesh: default
        name: retry-1
        spec:
          targetRef:
            kind: Mesh
        ---
        type: MeshRetry
        mesh: default
        name: retry-2
        spec:
          targetRef:
            kind: Mesh
        ```
        {% endpolicy_yaml %}
      LIQUID
    end

    it 'renders every document in the stream, in order' do
      expect(yaml_text(render(template), 'universal')).to eq(<<~YAML.strip)
        type: MeshRetry
        mesh: default
        name: retry-1
        spec:
          targetRef:
            kind: Mesh
        ---
        type: MeshRetry
        mesh: default
        name: retry-2
        spec:
          targetRef:
            kind: Mesh
      YAML
    end
  end

  describe 'an empty block body' do
    it 'renders nothing' do
      expect(render_liquid('{% policy_yaml %}{% endpolicy_yaml %}', page: page_with('2.10'), locals: locals).strip)
        .to eq('')
    end
  end
end
