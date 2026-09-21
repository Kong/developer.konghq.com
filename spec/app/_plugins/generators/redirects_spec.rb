# frozen_string_literal: true

require_relative '../../../../app/_plugins/generators/redirects'

RSpec.describe Jekyll::RefirectsGenerator do
  subject(:generator) { described_class.new }

  def policy(url:, get_started_url:)
    instance_double(Jekyll::Page, url:, data: { 'get_started_url' => get_started_url })
  end

  describe '#mesh_examples_redirects' do
    it 'emits no line for a current-major policy with no examples' do
      site = instance_double(
        Jekyll::Site,
        data: {
          'mesh_policies' => {
            3 => { 'meshaccesslog' => policy(url: '/mesh/policies/meshaccesslog/', get_started_url: nil) }
          }
        }
      )

      expect(generator.mesh_examples_redirects(site)).to eq([])
    end

    it 'still emits a line for a major-2 policy that has examples' do
      site = instance_double(
        Jekyll::Site,
        data: {
          'mesh_policies' => {
            2 => { 'meshretry' => policy(url: '/mesh/v2/policies/meshretry/', get_started_url: '/mesh/v2/policies/meshretry/examples/some-example/') }
          }
        }
      )

      expect(generator.mesh_examples_redirects(site)).to eq(
        ["/mesh/v2/policies/meshretry/examples/\t/mesh/v2/policies/meshretry/examples/some-example/"]
      )
    end

    it 'ignores the latest alias so a policy is not redirected twice' do
      major_3_policies = { 'meshretry' => policy(url: '/mesh/policies/meshretry/', get_started_url: '/mesh/policies/meshretry/examples/some-example/') }
      site = instance_double(
        Jekyll::Site,
        data: {
          'mesh_policies' => {
            3 => major_3_policies,
            'latest' => major_3_policies
          }
        }
      )

      expect(generator.mesh_examples_redirects(site)).to eq(
        ["/mesh/policies/meshretry/examples/\t/mesh/policies/meshretry/examples/some-example/"]
      )
    end
  end
end
