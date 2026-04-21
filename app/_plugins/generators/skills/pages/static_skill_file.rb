# frozen_string_literal: true

module Jekyll
  module SkillPages
    module Pages
      class StaticSkillFile < Jekyll::StaticFile
        # A StaticFile subclass that reads from the skill folder
        # but writes to the .well-known/skills/ output directory.
        def initialize(site, skill_folder, dest_dir, name, relative_path)
          super(site, skill_folder, dest_dir, name)
          @source_path = File.join(skill_folder, relative_path)
        end

        def path
          @source_path
        end
      end
    end
  end
end
