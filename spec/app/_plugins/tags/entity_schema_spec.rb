# frozen_string_literal: true

RSpec.describe Jekyll::RenderEntitySchema do
  let(:release) do
    Object.new.tap do |r|
      r.define_singleton_method(:label?)        { true }
      r.define_singleton_method(:ee_version)    { nil }
      r.define_singleton_method(:release_hash) { { 'name' => 'test-release' } }
    end
  end

  let(:schema) { { 'api' => 'konnect/test-api', 'path' => '/schemas/TestEntity' } }

  def render_entity_schema(output_format)
    render_liquid(
      '{% entity_schema %}',
      page: {
        'output_format' => output_format,
        'schema' => schema,
        'release' => release
      }
    )
  end

  def entity_schema_payload(html)
    script = html.find('script', visible: false).native.text.strip
    JSON.parse(script.delete_prefix('window.entitySchema = '))
  end

  describe 'markdown output' do
    subject(:rendered) { render_entity_schema('markdown') }

    it 'renders the flattened schema in a json block, leaving only the recursive ref literal' do
      expect(rendered).to eq(<<~MARKDOWN.chomp)
        ```json
        {
          "discriminator": {
            "propertyName": "type"
          },
          "oneOf": [
            {
              "type": "object",
              "properties": {
                "type": {
                  "type": "string"
                },
                "name": {
                  "type": "string",
                  "description": "The entity name."
                }
              }
            },
            {
              "type": "object",
              "properties": {
                "type": {
                  "type": "string"
                },
                "children": {
                  "type": "array",
                  "items": {
                    "$ref": "#/components/schemas/Group"
                  }
                }
              }
            }
          ]
        }
        ```
      MARKDOWN
    end

    it 'renders null instead of raising when the component is missing from the spec' do
      rendered = render_liquid(
        '{% entity_schema %}',
        page: {
          'output_format' => 'markdown',
          'schema' => { 'api' => 'konnect/test-api', 'path' => '/schemas/Missing' },
          'release' => release
        }
      )

      expect(rendered).to eq("```json\nnull\n```")
    end
  end

  describe 'html output' do
    subject(:rendered) { render_entity_schema('html') }

    let(:html) { Capybara::Node::Simple.new(rendered) }

    it 'mounts the client-side schema renderer' do
      expect(html).to have_css('#entity-schema-app')
      expect(html).to have_css('script', visible: false)
    end

    it 'passes the entity config payload and no dereferenced schema JSON' do
      expect(entity_schema_payload(html)).to eq(
        'product' => { 'id' => '11111111-1111-1111-1111-111111111111' },
        'version' => { 'id' => '22222222-2222-2222-2222-222222222222' },
        'path' => '/schemas/TestEntity'
      )
    end
  end
end
