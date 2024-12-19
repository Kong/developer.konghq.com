# frozen_string_literal: true

Jekyll::Hooks.register :site, :pre_render do |site|
  site.pages.reject! { |page| page.data['published'] == false }
end
