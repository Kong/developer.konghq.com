# frozen_string_literal: true

require_relative '../config_example/base'

module Jekyll
  module Drops
    module PolicyConfigExample
      class Base < Liquid::Drop # rubocop:disable Style/Documentation
        include ConfigExample::Base

        def url
          @url ||= if @plugin.unreleased?
                     "/#{@plugin.product}/policies/#{@plugin.slug}/examples/#{slug}/#{@plugin.min_release}"
                   else
                     "/#{@plugin.product}/policies/#{@plugin.slug}/examples/#{slug}/"
                   end
        end
      end
    end
  end
end
