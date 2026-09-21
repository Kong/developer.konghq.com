# frozen_string_literal: true

require 'yaml'

RSpec.describe Jekyll::RenderPolicyYaml do
  let(:locals) { {} }
  let(:page) { nil }

  def release(number)
    Jekyll::Drops::Release.new('release' => number)
  end

  def page_with(release_number, major_version: nil)
    page = { 'output_format' => 'html', 'path' => 'test.md', 'content' => '', 'release' => release(release_number) }
    page['major_version'] = { 'mesh' => major_version } if major_version
    page
  end

  def render(template, release_number: '2.10')
    Capybara::Node::Simple.new(render_liquid(template, page: page || page_with(release_number), locals: locals))
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

    it 'renders the Kubernetes, Universal, and Terraform tabs for a pre-2.10 release' do
      expect(tab_titles(render(template, release_number: '2.9'))).to eq(%w[Kubernetes Universal Terraform])
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

    it 'renders a Terraform tab' do
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
    let(:page) { page_with('2.10', major_version: 2) }

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

  describe 'version-aware style selection (major_version.mesh)' do
    let(:template) do
      <<~LIQUID
        {% policy_yaml use_meshservice=true %}
        ```yaml
        type: MeshRetry
        mesh: default
        name: retry
        spec:
          to:
            - targetRef:
                kind: MeshService
                name: backend
                namespace: kuma-demo
                sectionName: http
              default:
                action: Allow
        ```
        {% endpolicy_yaml %}
      LIQUID
    end

    describe 'a v3 page (no major_version) renders MeshService-based configurations only' do
      let(:page) { page_with('3.0') }

      it 'renders one code block per tab, in the MeshService form' do
        html = render(template)

        expect(html.find('div[data-panel="kubernetes"]').all('code').length).to eq(1)
        expect(yaml_text(html, 'kubernetes')).to eq(<<~YAML.strip)
          apiVersion: kuma.io/v1alpha1
          kind: MeshRetry
          metadata:
            name: retry
            namespace: kong-mesh-system
            labels:
              kuma.io/mesh: default
          spec:
            to:
            - targetRef:
                kind: MeshService
                name: backend
                namespace: kuma-demo
                sectionName: http
              default:
                action: Allow
        YAML

        expect(html.find('div[data-panel="universal"]').all('code').length).to eq(1)
        expect(yaml_text(html, 'universal')).to eq(<<~YAML.strip)
          type: MeshRetry
          mesh: default
          name: retry
          spec:
            to:
            - targetRef:
                kind: MeshService
                name: backend
                sectionName: http
              default:
                action: Allow
        YAML
      end

      it 'does not show the MeshService opt-in checkbox' do
        expect(render(template)).not_to have_css('.meshservice')
      end

      it 'renders no variant labels in markdown output' do
        markdown = render_liquid(template, page: page.merge('output_format' => 'markdown'))

        expect(markdown).not_to include('tag-based naming')
        expect(markdown).not_to include('Using `MeshService`')
        expect(markdown).to include('sectionName: http')
      end
    end

    describe 'a v2 page (major_version.mesh: 2) keeps the legacy-plus-MeshService rendering' do
      let(:page) { page_with('2.10', major_version: 2) }

      it 'renders both blocks per tab with the opt-in checkbox' do
        html = render(template)

        expect(html).to have_css('.meshservice input.checkbox')
        expect(html.find('div[data-panel="kubernetes"]').all('code').length).to eq(2)
        expect(yaml_text(html, 'kubernetes', index: 0)).to include('name: backend_kuma-demo_svc')
        expect(yaml_text(html, 'kubernetes', index: 1)).to include('sectionName: http')
        expect(html.find('div[data-panel="universal"]').all('code').length).to eq(2)
      end

      it 'keeps the variant labels in markdown output' do
        markdown = render_liquid(template, page: page.merge('output_format' => 'markdown'))

        expect(markdown).to include('Using `kuma.io/service` tag-based naming')
        expect(markdown).to include('Using `MeshService` Kubernetes resources')
      end
    end
  end

  describe 'show_legacy / show_meshservice variant selection' do
    let(:template) do
      <<~LIQUID
        {% policy_yaml %}
        ```yaml
        type: MeshRetry
        mesh: default
        name: retry
        spec:
          to:
            - targetRef:
                kind: MeshService
                name: backend
                namespace: kuma-demo
                sectionName: http
              default:
                action: Allow
        ```
        {% endpolicy_yaml %}
      LIQUID
    end

    describe 'a v3 page (no major_version)' do
      let(:page) { page_with('3.0') }

      it 'still renders the MeshService block only' do
        html = render(template)

        expect(html).not_to have_css('.meshservice')
        expect(html.find('div[data-panel="kubernetes"]').all('code').length).to eq(1)
        expect(yaml_text(html, 'kubernetes')).to include('sectionName: http')
        expect(yaml_text(html, 'kubernetes')).not_to include('backend_kuma-demo_svc')
        expect(html.find('div[data-panel="universal"]').all('code').length).to eq(1)
      end
    end

    describe 'a v2 page (major_version.mesh: 2)' do
      let(:page) { page_with('2.10', major_version: 2) }

      it 'shows the legacy block only' do
        html = render(template)

        expect(html).not_to have_css('.meshservice')
        expect(html.find('div[data-panel="kubernetes"]').all('code').length).to eq(1)
        expect(yaml_text(html, 'kubernetes')).to include('name: backend_kuma-demo_svc')
        expect(yaml_text(html, 'kubernetes')).not_to include('sectionName: http')
      end
    end
  end

  describe 'TargetRefTransform key emission (v3 non-legacy refs)' do
    let(:page) { page_with('3.0') }

    describe 'a name-based MeshService targetRef without namespace/sectionName' do
      let(:template) do
        <<~LIQUID
          {% policy_yaml %}
          ```yaml
          type: MeshRetry
          mesh: default
          name: retry
          spec:
            to:
              - targetRef:
                  kind: MeshService
                  name: backend
                default:
                  action: Allow
          ```
          {% endpolicy_yaml %}
        LIQUID
      end

      it 'emits no empty namespace/sectionName keys' do
        html = render(template)

        expect(yaml_text(html, 'kubernetes')).to eq(<<~YAML.strip)
          apiVersion: kuma.io/v1alpha1
          kind: MeshRetry
          metadata:
            name: retry
            namespace: kong-mesh-system
            labels:
              kuma.io/mesh: default
          spec:
            to:
            - targetRef:
                kind: MeshService
                name: backend
              default:
                action: Allow
        YAML

        expect(yaml_text(html, 'universal')).to eq(<<~YAML.strip)
          type: MeshRetry
          mesh: default
          name: retry
          spec:
            to:
            - targetRef:
                kind: MeshService
                name: backend
              default:
                action: Allow
        YAML
      end
    end

    describe 'a labels-based MeshMultiZoneService targetRef (no name)' do
      let(:template) do
        <<~LIQUID
          {% policy_yaml %}
          ```yaml
          type: MeshRetry
          mesh: default
          name: retry
          spec:
            to:
              - targetRef:
                  kind: MeshMultiZoneService
                  labels:
                    kuma.io/display-name: backend
                default:
                  action: Allow
          ```
          {% endpolicy_yaml %}
        LIQUID
      end

      it 'passes the ref through unchanged' do
        html = render(template)

        expect(yaml_text(html, 'kubernetes')).to eq(<<~YAML.strip)
          apiVersion: kuma.io/v1alpha1
          kind: MeshRetry
          metadata:
            name: retry
            namespace: kong-mesh-system
            labels:
              kuma.io/mesh: default
          spec:
            to:
            - targetRef:
                kind: MeshMultiZoneService
                labels:
                  kuma.io/display-name: backend
              default:
                action: Allow
        YAML

        expect(yaml_text(html, 'universal')).to eq(<<~YAML.strip)
          type: MeshRetry
          mesh: default
          name: retry
          spec:
            to:
            - targetRef:
                kind: MeshMultiZoneService
                labels:
                  kuma.io/display-name: backend
              default:
                action: Allow
        YAML
      end
    end
  end

  describe 'BackendRefTransform key emission (v3 non-legacy refs)' do
    let(:page) { page_with('3.0') }

    let(:template) do
      <<~LIQUID
        {% policy_yaml %}
        ```yaml
        type: MeshTCPRoute
        mesh: default
        name: frontend-to-backend
        spec:
          to:
            - targetRef:
                kind: Mesh
              rules:
                - default:
                    backendRefs:
                      - kind: MeshService
                        labels:
                          kuma.io/display-name: backend
                        port: 5432
                    filters:
                      - type: RequestMirror
                        requestMirror:
                          backendRef:
                            kind: MeshService
                            labels:
                              kuma.io/display-name: backend-replica
                            port: 8080
        ```
        {% endpolicy_yaml %}
      LIQUID
    end

    it 'passes labels-based backendRefs through unchanged, with no empty name keys' do
      html = render(template)

      expect(yaml_text(html, 'kubernetes')).to eq(<<~YAML.strip)
        apiVersion: kuma.io/v1alpha1
        kind: MeshTCPRoute
        metadata:
          name: frontend-to-backend
          namespace: kong-mesh-system
          labels:
            kuma.io/mesh: default
        spec:
          to:
          - targetRef:
              kind: Mesh
            rules:
            - default:
                backendRefs:
                - kind: MeshService
                  labels:
                    kuma.io/display-name: backend
                  port: 5432
                filters:
                - type: RequestMirror
                  requestMirror:
                    backendRef:
                      kind: MeshService
                      labels:
                        kuma.io/display-name: backend-replica
                      port: 8080
      YAML

      expect(yaml_text(html, 'universal')).to eq(<<~YAML.strip)
        type: MeshTCPRoute
        mesh: default
        name: frontend-to-backend
        spec:
          to:
          - targetRef:
              kind: Mesh
            rules:
            - default:
                backendRefs:
                - kind: MeshService
                  labels:
                    kuma.io/display-name: backend
                  port: 5432
                filters:
                - type: RequestMirror
                  requestMirror:
                    backendRef:
                      kind: MeshService
                      labels:
                        kuma.io/display-name: backend-replica
                      port: 8080
      YAML
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
