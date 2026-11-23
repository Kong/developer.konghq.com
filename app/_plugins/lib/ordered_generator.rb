# frozen_string_literal: true

module Jekyll
  # Base class for the generators run by Jekyll::GeneratorOrchestrator.
  #
  # Deliberately not a Jekyll::Plugin. Jekyll discovers Generator subclasses and
  # sorts them with an unstable sort that only compares priority bands, so ties
  # resolve differently between machines. Subclasses of this base are invisible
  # to that mechanism and run in the explicit order the orchestrator declares.
  class OrderedGenerator
    def initialize(_config = {}); end

    def generate(site)
      raise NotImplementedError, "#{self.class} must implement #generate"
    end
  end
end
