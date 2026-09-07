# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::MeshPolicyPages::Generator do
  let(:site) { JekyllSite.instance }

  before do
    allow(Jekyll).to receive(:sites).and_return([site])
    site.data['mesh_policies'] = {}
    described_class.run(site)
  end

  describe 'discovery' do
    it 'discovers a top-level policy present in the current policy major' do
      expect(site.data['mesh_policies'][3]).to have_key('meshretry')
    end

    it 'discovers a policy inside the v2 version subfolder' do
      expect(site.data['mesh_policies'][2]).to have_key('meshretry')
    end

    it 'discovers a policy that only exists in the v2 version subfolder' do
      expect(site.data['mesh_policies'][2]).to have_key('meshratelimit-legacy')
    end

    it 'does not leak a v2-only policy into the current policy major' do
      expect(site.data['mesh_policies'][3]).not_to have_key('meshratelimit-legacy')
    end

    it 'does not treat the version subfolder itself as a policy slug' do
      expect(site.data['mesh_policies'].values.flat_map(&:keys)).not_to include('v2')
    end
  end

  describe 'the current-major alias' do
    it 'points `latest` at the current policy major table' do
      expect(site.data['mesh_policies']['latest']).to equal(site.data['mesh_policies'][3])
    end
  end

  describe 'addresses' do
    it 'gives the current-major overview page the plain address' do
      overview = site.data['mesh_policies'][3]['meshretry']
      expect(overview.url).to eq('/mesh/policies/meshretry/')
    end

    it 'gives the v2 overview page the versioned address' do
      overview = site.data['mesh_policies'][2]['meshretry']
      expect(overview.url).to eq('/mesh/v2/policies/meshretry/')
    end

    it 'gives the current-major reference page the plain address' do
      reference = site.pages.find { |p| p.url == '/mesh/policies/meshretry/reference/' }
      expect(reference).not_to be_nil
    end

    it 'gives the v2 reference page the versioned address' do
      reference = site.pages.find { |p| p.url == '/mesh/v2/policies/meshretry/reference/' }
      expect(reference).not_to be_nil
    end
  end

  describe 'breadcrumbs' do
    it 'leads the current-major overview back to the plain mesh landing page and hub' do
      overview = site.data['mesh_policies'][3]['meshretry']
      expect(overview.data['breadcrumbs']).to eq(['/mesh/', '/mesh/policies/'])
    end

    it 'leads the v2 overview back to the v2 mesh landing page and hub' do
      overview = site.data['mesh_policies'][2]['meshretry']
      expect(overview.data['breadcrumbs']).to eq(['/mesh/v2/', '/mesh/v2/policies/'])
    end
  end

  describe 'release resolution' do
    it 'resolves the current-major policy release inside major 3' do
      overview = site.data['mesh_policies'][3]['meshretry']
      expect(overview.data['release'].number).to eq('3.0')
    end

    it 'resolves the v2 policy release inside major 2' do
      overview = site.data['mesh_policies'][2]['meshretry']
      expect(overview.data['release'].number).to eq('2.2')
    end
  end
end
