# frozen_string_literal: true

Jekyll::Hooks.register :site, :after_init do |site|
  site.config['skip'] = {} if ENV['JEKYLL_ENV'] == 'test'
end
