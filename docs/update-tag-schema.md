# Internal Docs: How to Add a New Tag to the Tag Schema

The [Tag Schema](https://github.com/Kong/developer.konghq.com/blob/main/app/_data/schemas/frontmatter/tags.json) is a predefined list of tags used in our documentation front‑matter to categorize, filter, and group content. Tags improve search results, navigation, related resources, filtering by topic, UI display, and also support internal CI validation.

## Where the Tag Schema lives

The schema is defined in: 

* [**developer.konghq.com/app/_data/schemas/frontmatter/tags.json**](http://developer.konghq.com/app/_data/schemas/frontmatter/tags.json)  

The build pipeline for documentation includes validation that tags used in front‑matter are among those defined in this tag schema. If an unknown tag is used, the build fails.

## Tag naming conventions

When you add a new tag, follow these rules to name it:

- [ ] Use lowercase letters only.   
- [ ] Use hyphens (-) to separate words. For example, `dev-portal-customization`.  
- [ ] Use only the following characters:   
      - [ ] Letters `a‑z`  
      - [ ] Digits `0‑9`  
      - [ ] Hyphens only

**Important**: Tags that include spaces, uppercase letters, or special characters will break the build.

## How to add a new tag

To add a new tag to the Tag Schema:

1. Clone or fork the docs repository locally.  
2. From your editor, in the **developer.konghq.com** repo, navigate to [**/app/_data/schemas/frontmatter/tags.json**](http://developer.konghq.com/app/_data/schemas/frontmatter/tags.json).  
3. In alphabetical order, add the new tag into the schema list.  
4. In any content pages that use the new tag, in the front matter, add the tag under the `tags:` field.  
5. Run a local docs build to confirm that there are no build errors.  
6. Create a PR with a clear commit message. For example, `docs: add tag new-tag-name` and explain why this tag is needed.  
7. Request review from docs.  
8. Once the PR is merged, notify the team that there's a new tag available for use.

## Test, Build Validation, and Troubleshoot

Use the following helpful checklist to refine your experience:

- [ ] After submitting the PR, check the CI build output for an error about an “Unknown tag”. If you see that, you likely forgot to add the tag to the schema.  
- [ ] Check for common errors present like, spaces, uppercase letters, or special characters in tag names that are not allowed by the schema.

### Workflow example

If you needed to add a new tag called `kong-tag-example`:

1. In `tags.json`, in alphabetical order, add `kong-tag-example`.  
2. In the front matter of `example‑page.md`, add the new tag:  
   `tags:`  
    `‑ metrics`  
    `‑ kong-tag-example`  
3. Run your local build and verify that there are no errors.  
4. Open a PR: `docs: add tag kong-tag-example` with explanation.  
5. Tag and request review by *docs-maintainers*.  
6. Once merged, communicate to the team that this tag exists and can be used.
