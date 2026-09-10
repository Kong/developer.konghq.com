# frozen_string_literal: true

RSpec.describe 'how-tos/validations/vault-secret/snippet.md' do
  let(:template) do
    '{% include how-tos/validations/vault-secret/snippet.md container=container secret=secret command=command %}'
  end

  subject(:rendered) do
    render_liquid(template, locals: { 'container' => container, 'secret' => secret, 'command' => command })
  end

  let(:code) { bash_code_block(rendered) }

  shared_examples 'a valid bash command' do
    it 'renders syntactically valid bash' do
      validate_bash_syntax!(code)
    end
  end

  context 'no command override' do
    let(:container) { 'kong-quickstart-gateway' }
    let(:secret) { '{vault://hashicorp-vault/customer/acme/name}' }
    let(:command) { '' }

    include_examples 'a valid bash command'

    it 'wraps kong vault get in a docker exec against the container' do
      expect(rendered).to eq(<<~'MD'.chomp)
        ```bash
        docker exec kong-quickstart-gateway kong vault get {vault://hashicorp-vault/customer/acme/name}
        ```
      MD
    end
  end

  context 'a command override' do
    let(:container) { 'kong-gateway' }
    let(:secret) { '{vault://aws-vault/my-aws-secret/token}' }
    let(:command) { 'kubectl exec -n kong -it deployment/kong-gateway -c proxy --' }

    include_examples 'a valid bash command'

    it 'uses the given command in place of docker exec, ignoring container' do
      expect(rendered).to eq(<<~'MD'.chomp)
        ```bash
        kubectl exec -n kong -it deployment/kong-gateway -c proxy -- kong vault get {vault://aws-vault/my-aws-secret/token}
        ```
      MD
    end
  end
end
