# frozen_string_literal: true

RSpec.describe Jekyll::Drops::KongConf do
  let(:kong_conf_index) do
    {
      'sections' => [
        { 'title' => 'General', 'description' => 'General settings' },
        { 'title' => 'Nginx', 'description' => 'Nginx settings' }
      ],
      'params' => {
        'log_level' => { 'sectionTitle' => 'General', 'defaultValue' => 'notice' },
        'admin_listen' => { 'sectionTitle' => 'General', 'defaultValue' => '127.0.0.1:8001' },
        'proxy_listen' => { 'sectionTitle' => 'Nginx',   'defaultValue' => '0.0.0.0:8000' }
      }
    }
  end

  before { stub_const('Jekyll::Drops::KongConf::KONG_CONF_INDICES', { 'gateway' => kong_conf_index }) }

  subject(:drop) { described_class.new('gateway') }

  describe '#sections' do
    it 'returns a Section for each section in the index' do
      expect(drop.sections.size).to eq(2)
    end

    it { expect(drop.sections).to all(be_a(Jekyll::Drops::KongConf::Section)) }

    it 'preserves section order' do
      expect(drop.sections.map(&:title)).to eq(%w[General Nginx])
    end

    it 'assigns only params whose sectionTitle matches the section title' do
      general = drop.sections.find { |s| s.title == 'General' }
      expect(general.parameters.map { |p| p['name'] }).to contain_exactly('log_level', 'admin_listen')
    end
  end

  context 'when sections are empty' do
    let(:kong_conf_index) { { 'sections' => [], 'params' => {} } }

    it { expect(drop.sections).to be_empty }
  end

  context 'when a section has no matching params' do
    let(:kong_conf_index) do
      {
        'sections' => [{ 'title' => 'Orphan' }],
        'params' => { 'log_level' => { 'sectionTitle' => 'General' } }
      }
    end

    it 'creates the section with empty parameters' do
      expect(drop.sections.first.parameters).to be_empty
    end
  end

  context 'with ai-gateway product' do
    let(:ai_gateway_index) do
      {
        'sections' => [{ 'title' => 'AI', 'description' => 'AI settings' }],
        'params' => { 'model' => { 'sectionTitle' => 'AI', 'defaultValue' => 'gpt-4' } }
      }
    end

    before do
      stub_const('Jekyll::Drops::KongConf::KONG_CONF_INDICES',
                 { 'gateway' => kong_conf_index, 'ai-gateway' => ai_gateway_index })
    end

    subject(:drop) { described_class.new('ai-gateway') }

    it { expect(drop.sections.map(&:title)).to eq(['AI']) }

    it 'assigns params to the correct section' do
      expect(drop.sections.first.parameters.map { |p| p['name'] }).to contain_exactly('model')
    end
  end

  context 'when product has no index entry' do
    subject(:drop) { described_class.new('unknown') }

    it { expect(drop.sections).to be_empty }
  end

  context 'when no product is given (defaults to gateway)' do
    subject(:drop) { described_class.new }

    it { expect(drop.sections.size).to eq(2) }
  end

  describe Jekyll::Drops::KongConf::Section do
    let(:section_data) { { 'title' => 'General', 'description' => 'General settings' } }
    let(:params) do
      {
        'log_level' => { 'sectionTitle' => 'General', 'defaultValue' => 'notice' },
        'admin_listen' => { 'sectionTitle' => 'General', 'defaultValue' => '127.0.0.1:8001' }
      }
    end

    subject(:section) { described_class.new(section: section_data, params:) }

    describe '#title' do
      it { expect(section.title).to eq('General') }
    end

    describe '#description' do
      it { expect(section.description).to eq('General settings') }

      context 'when description is absent' do
        let(:section_data) { { 'title' => 'General' } }

        it { expect(section.description).to be_nil }
      end
    end

    describe '#parameters' do
      it 'returns one entry per param' do
        expect(section.parameters.size).to eq(2)
      end

      it 'injects the param key as the name field' do
        names = section.parameters.map { |p| p['name'] }
        expect(names).to contain_exactly('log_level', 'admin_listen')
      end

      it 'merges the param attributes alongside name' do
        log_param = section.parameters.find { |p| p['name'] == 'log_level' }
        expect(log_param['defaultValue']).to eq('notice')
      end

      context 'when params are empty' do
        let(:params) { {} }

        it { expect(section.parameters).to be_empty }
      end
    end
  end
end
