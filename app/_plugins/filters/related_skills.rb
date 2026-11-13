# frozen_string_literal: true

# Returns up to three Skills Hub skills that share tags with a page.
# Tags that appear on more than half of all skills (for example `kong` and
# `konnect`) are ignored, because they match almost every page.
module RelatedSkillsFilter
  MAX_SKILLS = 3

  def related_skills(page_tags)
    page_tags = Array(page_tags).map(&:to_s)
    return [] if page_tags.empty?

    skills = (@context.registers[:site].data['skills'] || {}).values
    return [] if skills.empty?

    useful_tags = page_tags - generic_skill_tags(skills)
    return [] if useful_tags.empty?

    skills
      .map { |skill| [skill, (Array(skill.data['tags']).map(&:to_s) & useful_tags).size] }
      .select { |_, score| score.positive? }
      .sort_by { |skill, score| [-score, skill.data['title'].to_s.downcase] }
      .first(MAX_SKILLS)
      .map { |skill, _| { 'title' => skill.data['title'], 'url' => skill.url } }
  end

  private

  def generic_skill_tags(skills)
    counts = Hash.new(0)
    skills.each { |skill| Array(skill.data['tags']).map(&:to_s).uniq.each { |tag| counts[tag] += 1 } }
    counts.select { |_, count| count > skills.size / 2.0 }.keys
  end
end

Liquid::Template.register_filter(RelatedSkillsFilter)
