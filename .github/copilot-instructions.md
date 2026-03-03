This is a docs repository for the Kong Developer site (https://developer.konghq.com/). We use Jekyll, Netlify, Ruby, and then write our docs in Markdown and YAML. Please use these guidelines when you are asked to create a PR, write a commit, or review a PR:

## Required Before Each Commit
- Run `make run` before committing any changes to ensure there aren't any issues with the site building

## Repository Structure
- The /tools directory contains all the information about how our different tooling works, such as automated tests, autogenerating new plugin scaffolding, and changelog generator

## PR Review Philosophy
- When you leave PR reviews, always provide GitHub suggestions with actionable feedback that the PR creator can directly commit.
For example, don't say "Change this variable.", instead, create a comment with a suggestion that changes the variable to the correct one.
- Only comment when you have HIGH CONFIDENCE (>80%) that an issue exists
- Be concise: one sentence per comment when possible
- If you're uncertain whether something is an issue, don't comment. False positives create noise and reduce trust in the review process.

## Key Guidelines
- We write three types of docs: reference, landing page (written in yaml), and how-tos
- When you write or edit a doc, use app/contributing/index.md to format the body text (as well as code blocks) correctly for each page type
- When writing or editing UI steps, use the formats listed in docs/ui-steps-standards.md
- When adding tags to the frontmatter, follow the instructions here: docs/update-tag-schema.md
- For anything that is added to the frontmatter of a doc, use docs/front-matter-reference.md for a reference
