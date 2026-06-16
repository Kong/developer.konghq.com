source 'https://rubygems.org'

gem 'activesupport'
gem 'csv'
gem 'jekyll'
gem 'jekyll-include-cache'
gem 'jekyll-vite'
gem 'vite_ruby', '~> 3.10' # keep in sync with vite npm package (currently v8)
gem 'kramdown-parser-gfm'
gem 'liquid-c'
gem 'nodo'
gem 'nokogiri'
gem 'nokolexbor'
gem 'rouge', '~> 4.3'
# XXX: bundler isn't installing mini_portile as a dependency of nokogiri
# installing it manually fixes the issue
gem 'mini_portile2', '~> 2.8'

group :development do
  gem 'byebug'
  gem 'foreman'
  gem 'pry'
  gem 'puma'
  gem 'rubocop'
end

group :jekyll_plugins do
  gem 'jekyll-contentblocks'
end
