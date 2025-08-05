# frozen_string_literal: true

Jekyll::Hooks.register :site, :after_init do |site|
  if ENV['JEKYLL_ENV'] == 'test'
    site.config['skip'] = {}
    site.config['exclude'].delete('_references')
  end
end
