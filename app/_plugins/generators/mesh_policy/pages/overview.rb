# frozen_string_literal: true

require_relative '../../policies/pages/overview'

module Jekyll
  module MeshPolicyPages
    module Pages
      class Overview < Base
        include Policies::Pages::Overview
      end
    end
  end
end
