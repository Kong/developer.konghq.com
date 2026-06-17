# frozen_string_literal: true

RSpec.describe Jekyll::Drops::Prereqs do
  let(:page_data) { { 'prereqs' => {}, 'tools' => [], 'products' => [] } }
  let(:page) { instance_double(Jekyll::Page, data: page_data, url: '/test/') }
  let(:site_data) { { 'products' => {} } }
  let(:site) { instance_double(Jekyll::Site, data: site_data, source: '/source') }

  subject(:drop) { described_class.new(page:, site:) }

  describe '#[]' do
    context 'when key matches a public method' do
      it 'delegates to the method' do
        expect(drop['tools']).to eq([])
      end
    end

    context 'when key does not match a method' do
      let(:page_data) { super().merge('prereqs' => { 'custom_key' => 'custom_value' }) }

      it 'looks up the key in prereqs' do
        expect(drop['custom_key']).to eq('custom_value')
      end
    end
  end

  describe '#default_accordion' do
    context 'when expand_accordion is false' do
      let(:page_data) { super().merge('prereqs' => { 'expand_accordion' => false }) }

      it { expect(drop.default_accordion).to eq('') }
    end

    context 'when expand_accordion is not set' do
      it { expect(drop.default_accordion).to eq('data-default="0"') }
    end

    context 'when expand_accordion is true' do
      let(:page_data) { super().merge('prereqs' => { 'expand_accordion' => true }) }

      it { expect(drop.default_accordion).to eq('data-default="0"') }
    end
  end

  describe '#render_works_on?' do
    context 'when show_works_on is set in prereqs' do
      context 'when show_works_on is false' do
        let(:page_data) { super().merge('prereqs' => { 'show_works_on' => false }) }

        it { expect(drop.render_works_on?).to be(false) }

        context 'when series position is greater than 1' do
          let(:page_data) { super().merge('series' => { 'position' => 2 }) }

          it { expect(drop.render_works_on?).to be(false) }
        end
      end

      context 'when show_works_on is true' do
        let(:page_data) { super().merge('prereqs' => { 'show_works_on' => true }) }

        it { expect(drop.render_works_on?).to be(true) }
      end
    end

    context 'when show_works_on is not set in prereqs' do
      context 'when series position is greater than 1' do
        let(:page_data) { super().merge('series' => { 'position' => 2 }) }

        it { expect(drop.render_works_on?).to be(false) }
      end

      context 'when series position is 1' do
        let(:page_data) { super().merge('series' => { 'position' => 1 }) }

        it { expect(drop.render_works_on?).to be(true) }
      end
    end

    context 'when nothing is set' do
      it { expect(drop.render_works_on?).to be(true) }
    end
  end

  describe '#konnect_auth_only?' do
    context 'when works_on includes konnect' do
      let(:page_data) { super().merge('works_on' => ['konnect']) }

      context 'when render_works_on? is false' do
        let(:page_data) { super().merge('series' => { 'position' => 2 }) }

        it { expect(drop.konnect_auth_only?).to be(false) }
      end

      context 'when render_works_on? is true' do
        context 'when products include gateway' do
          let(:page_data) { super().merge('products' => ['gateway']) }

          it { expect(drop.konnect_auth_only?).to be(false) }
        end

        context 'when products include ai-gateway' do
          let(:page_data) { super().merge('products' => ['ai-gateway']) }

          it { expect(drop.konnect_auth_only?).to be(false) }
        end

        context 'when products do not include gateway or ai-gateway' do
          let(:page_data) { super().merge('products' => ['mesh']) }

          it { expect(drop.konnect_auth_only?).to be(true) }
        end
      end
    end

    context 'when works_on does not include konnect' do
      let(:page_data) { super().merge('works_on' => ['on-prem']) }

      it { expect(drop.konnect_auth_only?).to be(false) }
    end
  end

  describe '#inline_before' do
    context 'with mixed position items' do
      let(:page_data) do
        super().merge('prereqs' => {
                        'inline' => [
                          { 'text' => 'first', 'position' => 'before' },
                          { 'text' => 'second', 'position' => 'after' },
                          { 'text' => 'third' }
                        ]
                      })
      end

      it 'returns only items with position before' do
        expect(drop.inline_before).to contain_exactly({ 'text' => 'first', 'position' => 'before' })
      end
    end

    context 'when no inline items are set' do
      it { expect(drop.inline_before).to be_empty }
    end
  end

  describe '#inline_without_position' do
    context 'with mixed position items' do
      let(:page_data) do
        super().merge('prereqs' => {
                        'inline' => [
                          { 'text' => 'no position' },
                          { 'text' => 'with position', 'position' => 'before' }
                        ]
                      })
      end

      it 'returns only items without a position key' do
        expect(drop.inline_without_position).to contain_exactly({ 'text' => 'no position' })
      end
    end

    context 'when no inline items are set' do
      it { expect(drop.inline_without_position).to be_empty }
    end
  end

  describe '#any?' do
    context 'when tools are present' do
      let(:page_data) { super().merge('tools' => ['deck']) }

      it { expect(drop.any?).to be(true) }
    end

    context 'when products are present' do
      let(:page_data) { super().merge('products' => ['mesh']) }

      it { expect(drop.any?).to be(true) }

      context 'when skip_product is true' do
        let(:page_data) { super().merge('prereqs' => { 'skip_product' => true }, 'products' => ['mesh']) }

        it { expect(drop.any?).to be(false) }
      end
    end

    context 'when all are empty' do
      it { expect(drop.any?).to be(false) }
    end

    context 'when prereqs has non-skip keys' do
      let(:page_data) { super().merge('prereqs' => { 'entities' => { 'services' => ['basic'] } }) }

      it { expect(drop.any?).to be(true) }
    end

    context 'when only show_works_on is false' do
      let(:page_data) { super().merge('prereqs' => { 'show_works_on' => false }) }

      it { expect(drop.any?).to be(false) }
    end
  end

  describe '#entities?' do
    context 'when entities are present' do
      let(:page_data) { super().merge('prereqs' => { 'entities' => { 'services' => ['basic'] } }) }

      it { expect(drop.entities?).to be(true) }
    end

    context 'when entities key is absent' do
      it { expect(drop.entities?).to be(false) }
    end

    context 'when entities is empty' do
      let(:page_data) { super().merge('prereqs' => { 'entities' => {} }) }

      it { expect(drop.entities?).to be(false) }
    end
  end

  describe '#inline' do
    context 'when inline items are set' do
      let(:items) { [{ 'text' => 'item1' }, { 'text' => 'item2' }] }
      let(:page_data) { super().merge('prereqs' => { 'inline' => items }) }

      it 'returns all inline items' do
        expect(drop.inline).to eq(items)
      end
    end

    context 'when no inline items are set' do
      it { expect(drop.inline).to be_empty }
    end
  end

  describe '#entities_product' do
    context 'when entities_product is set in prereqs' do
      let(:page_data) { super().merge('prereqs' => { 'entities_product' => 'kic' }) }

      it 'returns entities_product from prereqs' do
        expect(drop.entities_product).to eq('kic')
      end
    end

    context 'when entities_product is not set' do
      let(:page_data) { super().merge('products' => %w[mesh gateway]) }

      it 'falls back to the first product' do
        expect(drop.entities_product).to eq('mesh')
      end
    end

    context 'when product is operator' do
      let(:page_data) { super().merge('products' => ['operator']) }

      it 'converts operator to kic' do
        expect(drop.entities_product).to eq('kic')
      end
    end
  end

  describe '#entities_product_include' do
    let(:entities_includes) do
      [
        'app/_includes/prereqs/entities/mesh.md',
        'app/_includes/prereqs/entities/kic.md',
        'app/_includes/prereqs/entities/ai-gateway/v1.md',
        'app/_includes/prereqs/entities/ai-gateway.md'
      ]
    end

    before { stub_const('Jekyll::Drops::ProductEntitiesPrereqs::ENTITIES_INCLUDES', entities_includes) }

    context 'page without major_version set' do
      context 'when entities_product is set in prereqs' do
        let(:page_data) { super().merge('prereqs' => { 'entities_product' => 'kic' }) }

        it 'returns entities_product from prereqs' do
          expect(drop.entities_product_include).to eq('prereqs/entities/kic.md')
        end
      end

      context 'when entities_product is not set' do
        let(:page_data) { super().merge('products' => %w[mesh gateway]) }

        it 'falls back to the first product' do
          expect(drop.entities_product_include).to eq('prereqs/entities/mesh.md')
        end

        context 'when there are multiple major versions of a product' do
          let(:page_data) { super().merge('products' => %w[ai-gateway]) }
          it 'it returns the include file without a version, which corresponds to the latest major version' do
            expect(drop.entities_product_include).to eq('prereqs/entities/ai-gateway.md')
          end
        end
      end

      context 'when product is operator' do
        let(:page_data) { super().merge('products' => ['operator']) }

        it 'converts operator to kic' do
          expect(drop.entities_product_include).to eq('prereqs/entities/kic.md')
        end
      end
    end

    context 'page with major_version set' do
      let(:page_data) do
        {
          'prereqs' => {},
          'tools' => [],
          'products' => ['ai-gateway'],
          'major_version' => { 'ai-gateway' => 1 }
        }
      end
      let(:site_data) do
        _data = super()
        _data['products']['ai-gateway'] =
          YAML.load_file(File.expand_path('../../../fixtures/app/_data/products/ai-gateway.yml', __dir__))
        _data
      end

      context 'when entities_product is set in prereqs' do
        let(:page_data) { super().merge('prereqs' => { 'entities_product' => 'kic' }) }

        it 'returns entities_product from prereqs' do
          expect(drop.entities_product_include).to eq('prereqs/entities/kic.md')
        end
      end

      context 'when entities_product is not set' do
        it 'falls back to the first product and its major_version of the file - using the segment path' do
          expect(drop.entities_product_include).to eq('prereqs/entities/ai-gateway/v1.md')
        end

        context 'when there is no include file for the product and major_version' do
          let(:entities_includes) do
            [
              'app/_includes/prereqs/entities/mesh.md',
              'app/_includes/prereqs/entities/kic.md',
              'app/_includes/prereqs/entities/ai-gateway.md'
            ]
          end
          it 'raises an error indicating the missing include file' do
            expect do
              drop.entities_product_include
            end.to raise_error(RuntimeError, 'No app/_includes/prereqs/entities/ai-gateway/v1 file found')
          end
        end
      end

      context 'when product is operator' do
        let(:page_data) { super().merge('products' => ['operator']) }

        it 'converts operator to kic' do
          expect(drop.entities_product_include).to eq('prereqs/entities/kic.md')
        end
      end
    end
  end

  describe '#data' do
    let(:entity_example) { { 'name' => 'test-service', 'url' => 'http://example.com' } }
    let(:site_data) { { 'entity_examples' => { 'gateway' => { 'services' => { 'basic' => entity_example } } } } }

    context 'when the first product is gateway' do
      let(:page_data) do
        super().merge(
          'products' => ['gateway'],
          'prereqs' => { 'entities' => { 'services' => ['basic'] } }
        )
      end

      it 'includes _format_version with double-quoted 3.0' do
        expect(drop.data).to include('_format_version: "3.0"')
      end

      it 'includes the entity data' do
        expect(drop.data).to include('test-service')
      end
    end

    context 'when the first product is not gateway' do
      let(:site_data) { { 'entity_examples' => { 'kic' => { 'services' => { 'basic' => entity_example } } } } }
      let(:page_data) do
        super().merge(
          'products' => ['kic'],
          'prereqs' => { 'entities' => { 'services' => ['basic'] } }
        )
      end

      it { expect(drop.data).to be_a(Hash) }

      it 'does not include _format_version' do
        expect(drop.data).not_to have_key('_format_version')
      end

      it 'includes the entity data' do
        expect(drop.data['services']).to include(entity_example)
      end
    end

    context 'when entity_example file is missing' do
      let(:site_data) { { 'entity_examples' => {} } }
      let(:page_data) do
        super().merge(
          'products' => ['gateway'],
          'prereqs' => { 'entities' => { 'services' => ['missing'] } }
        )
      end

      it 'raises ArgumentError mentioning the missing file path' do
        expect { drop.data }.to raise_error(ArgumentError, /entity_examples/)
      end
    end
  end

  describe '#products' do
    let(:product_includes) do
      [
        'app/_includes/prereqs/products/mesh.md',
        'app/_includes/prereqs/products/kic.md',
        'app/_includes/prereqs/products/ai-gateway/v1.md',
        'app/_includes/prereqs/products/ai-gateway.md'
      ]
    end

    before { stub_const('Jekyll::Drops::ProductIncludePrereqs::PRODUCT_INCLUDES', product_includes) }

    context 'when products include gateway and ai-gateway' do
      let(:page_data) { super().merge('products' => %w[gateway ai-gateway mesh]) }

      it 'skips gateway and ai-gateway and returns the rest of the products' do
        expect(drop.products).to eq(['mesh'])
      end
    end

    context 'when a product has no include file' do
      let(:page_data) { super().merge('products' => %w[mesh insomnia]) }

      it 'skips products with no include file and returns the rest' do
        expect(drop.products).to eq(['mesh'])
      end
    end

    context 'when products are empty' do
      it { expect(drop.products).to be_empty }
    end
  end

  describe '#tools' do
    context 'when tools are set' do
      let(:page_data) { super().merge('tools' => %w[deck httpie]) }

      it 'returns the tools array' do
        expect(drop.tools).to eq(%w[deck httpie])
      end
    end
  end

  describe '#enterprise' do
    context 'when min_version.gateway is not set' do
      let(:page_data) { super().merge('prereqs' => { 'enterprise' => true }, 'min_version' => {}) }

      before { drop.entities? }

      it 'returns the enterprise value from prereqs' do
        expect(drop.enterprise).to be(true)
      end
    end

    context 'when min_version.gateway is exactly 3.10' do
      let(:page_data) { super().merge('min_version' => { 'gateway' => '3.10' }) }

      it 'returns true' do
        expect(drop.enterprise).to be(true)
      end
    end

    context 'when min_version.gateway is greater than 3.10' do
      let(:page_data) { super().merge('min_version' => { 'gateway' => '3.11' }) }

      it 'returns true' do
        expect(drop.enterprise).to be(true)
      end
    end

    context 'when min_version.gateway is less than 3.10' do
      let(:page_data) { super().merge('min_version' => { 'gateway' => '3.9' }) }

      it 'returns false' do
        expect(drop.enterprise).to be(false)
      end
    end
  end
end
