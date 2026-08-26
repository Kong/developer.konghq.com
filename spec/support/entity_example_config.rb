# frozen_string_literal: true

def stub_entity_examples_config!
  config = YAML.load_file(File.join(PROJECT_ROOT, 'app/_data/entity_examples/config.yml'), aliases: true)
  site = instance_double(Jekyll::Site, data: { 'entity_examples' => { 'config' => config } })
  allow(Jekyll).to receive(:sites).and_return([site])
end
