# frozen_string_literal: true

RSpec.describe Jekyll::KumaSpecific::CpInstall do
  let(:page) do
    {
      'output_format' => 'markdown',
      'path' => 'test.md',
      'dir' => '/mesh/v2/',
      'release' => 'v2.6',
      'content' => ''
    }
  end
  let(:locals) { {} }

  subject { render_liquid(template, page: page, locals: locals) }

  describe 'rendering' do
    context 'with a single-line body' do
      let(:template) do
        <<~LIQUID
          {% cpinstall test %}
          skipRBAC=true
          {% endcpinstall %}
        LIQUID
      end

      it 'shows the same prefixed flag on both tabs' do
        expect(subject.scan('--set "kuma.skipRBAC=true"').length).to eq(2)
      end

      it 'renders a kumactl tab and a Helm tab' do
        expect(subject).to include('### kumactl')
        expect(subject).to include('### Helm')
      end
    end

    context 'with a multi-line body' do
      let(:template) do
        <<~LIQUID
          {% cpinstall test %}
          skipRBAC=true
          controlPlane.skipClusterRoleCreation=true
          {% endcpinstall %}
        LIQUID
      end

      it 'makes one flag per line, joined with a line continuation' do
        expect(subject).to include(
          "--set \"kuma.skipRBAC=true\" \\\n  --set \"kuma.controlPlane.skipClusterRoleCreation=true\""
        )
      end
    end

    context 'with a flag value that contains braces' do
      let(:template) do
        <<~LIQUID
          {% cpinstall test %}
          namespaceAllowList={first-namespace,second-namespace}
          {% endcpinstall %}
        LIQUID
      end

      it 'passes the value through unchanged' do
        expect(subject).to include('--set "kuma.namespaceAllowList={first-namespace,second-namespace}"')
      end
    end

    context 'with prefixed=false' do
      let(:template) do
        <<~LIQUID
          {% cpinstall test prefixed=false %}
          skipRBAC=true
          {% endcpinstall %}
        LIQUID
      end

      it 'removes the site prefix' do
        expect(subject).to include('--set "skipRBAC=true"')
        expect(subject).not_to include('kuma.skipRBAC')
      end
    end

    context 'with an empty body' do
      let(:template) do
        <<~LIQUID
          {% cpinstall test %}
          {% endcpinstall %}
        LIQUID
      end

      it 'renders nothing' do
        expect(subject.strip).to eq('')
      end
    end

    context 'the Helm tab' do
      let(:template) do
        <<~LIQUID
          {% cpinstall test %}
          skipRBAC=true
          {% endcpinstall %}
        LIQUID
      end

      it 'links to the setup instructions with the product segment and the page release' do
        expect(subject).to include('https://developer.konghq.com/mesh/v2.6/production/cp-deployment/kubernetes/#helm')
      end
    end

    context 'shell syntax' do
      let(:template) do
        <<~LIQUID
          {% cpinstall test %}
          skipRBAC=true
          {% endcpinstall %}
        LIQUID
      end

      it 'produces a valid kumactl shell block' do
        validate_bash_syntax!(bash_code_block(subject, lang: 'shell'))
      end
    end
  end
end
