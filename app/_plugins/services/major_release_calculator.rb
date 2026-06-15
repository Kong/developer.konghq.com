# frozen_string_literal: true

class MajorReleaseCalculator
  def initialize(page_data)
    @page_data = page_data
  end

  def previous_major?
    !major_version.nil?
  end

  def major_version
    @major_version ||= @page_data['major_version']
  end
end
