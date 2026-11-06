# frozen_string_literal: true

RSpec.describe Jekyll::Utils::JsonSchemaDeref do
  subject(:resolved) { described_class.new(schema).resolve }

  describe 'resolving #/$defs/ refs' do
    let(:schema) do
      {
        'type' => 'object',
        'properties' => {
          'name' => { '$ref' => '#/$defs/Name' }
        },
        '$defs' => {
          'Name' => { 'type' => 'string' }
        }
      }
    end

    it 'inlines the referenced definition in place of the $ref' do
      expect(resolved.dig('properties', 'name')).to eq('type' => 'string')
    end

    it 'excludes the $defs key from the resolved output' do
      expect(resolved).not_to have_key('$defs')
    end
  end

  describe 'resolving #/components/schemas/ refs' do
    let(:schema) do
      {
        'properties' => {
          'name' => { '$ref' => '#/components/schemas/Name' }
        },
        'components' => {
          'schemas' => {
            'Name' => { 'type' => 'string' }
          }
        }
      }
    end

    it 'inlines the referenced definition in place of the $ref' do
      expect(resolved.dig('properties', 'name')).to eq('type' => 'string')
    end
  end

  describe 'nested refs' do
    let(:schema) do
      {
        'properties' => {
          'pet' => { '$ref' => '#/$defs/Pet' }
        },
        '$defs' => {
          'Pet' => {
            'type' => 'object',
            'properties' => {
              'name' => { '$ref' => '#/$defs/Name' }
            }
          },
          'Name' => { 'type' => 'string' }
        }
      }
    end

    it 'inlines refs inside referenced definitions, recursively' do
      expect(resolved.dig('properties', 'pet', 'properties', 'name')).to eq('type' => 'string')
    end
  end

  describe 'sibling keys on a $ref' do
    let(:schema) do
      {
        'properties' => {
          'name' => {
            '$ref' => '#/$defs/Name',
            'description' => 'sibling description',
            'default' => 'anonymous'
          },
          'nickname' => {
            '$ref' => '#/$defs/Bare',
            'description' => 'sibling description'
          }
        },
        '$defs' => {
          'Name' => { 'type' => 'string', 'description' => 'referenced description' },
          'Bare' => { 'type' => 'string' }
        }
      }
    end

    it 'merges sibling keys into the referenced definition' do
      expect(resolved.dig('properties', 'name')).to include('type' => 'string', 'default' => 'anonymous')
    end

    it 'gives the referenced definition description precedence over the sibling' do
      expect(resolved.dig('properties', 'name', 'description')).to eq('referenced description')
    end

    it 'keeps the sibling description when the referenced definition has none' do
      expect(resolved.dig('properties', 'nickname', 'description')).to eq('sibling description')
    end
  end

  describe 'recursive refs' do
    let(:schema) do
      {
        'properties' => {
          'group' => { '$ref' => '#/$defs/Group' }
        },
        '$defs' => {
          'Group' => {
            'type' => 'object',
            'properties' => {
              'children' => {
                'type' => 'array',
                'items' => { '$ref' => '#/$defs/Group' }
              }
            }
          }
        }
      }
    end

    it 'expands the outer ref and leaves the recursive occurrence literal' do
      expect(resolved.dig('properties', 'group')).to eq(
        'type' => 'object',
        'properties' => {
          'children' => {
            'type' => 'array',
            'items' => { '$ref' => '#/$defs/Group' }
          }
        }
      )
    end
  end

  describe 'unresolvable refs' do
    let(:schema) do
      {
        'properties' => {
          'external' => { '$ref' => 'https://example.com/schemas/name.json' },
          'parameter' => { '$ref' => '#/components/parameters/Name' },
          'missing' => { '$ref' => '#/$defs/Missing' }
        },
        '$defs' => {
          'Name' => { 'type' => 'string' }
        }
      }
    end

    it 'leaves external URL refs literal' do
      expect(resolved.dig('properties', 'external')).to eq('$ref' => 'https://example.com/schemas/name.json')
    end

    it 'leaves non-schema component refs literal' do
      expect(resolved.dig('properties', 'parameter')).to eq('$ref' => '#/components/parameters/Name')
    end

    it 'leaves refs with no matching definition literal' do
      expect(resolved.dig('properties', 'missing')).to eq('$ref' => '#/$defs/Missing')
    end
  end
end
