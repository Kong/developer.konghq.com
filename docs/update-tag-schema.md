
The build pipeline for documentation includes validation that tags used in front‑matter are among those defined in this tag schema. If an unknown tag is used, the build fails.

## How to add a new tag to the Tag Schema

The [Tag Schema](https://github.com/Kong/developer.konghq.com/blob/main/app/_data/schemas/frontmatter/tags.json) is a predefined list of tags used in our documentation front‑matter to categorize, filter, and group content. 

Adding a new tag will cause the build to fail until you add the tag to the Tag schema.

## Tag naming conventions

When you add a new tag, follow these rules to name it:

- [ ] Use lowercase letters only.   
- [ ] Use hyphens (-) to separate words. For example, `dev-portal-customization`.  
- [ ] Use only the following characters:   
      - [ ] Letters `a‑z`
      - [ ] Digits `0‑9`
**Important**: Tags that include spaces, uppercase letters, or special characters will break the build.

## How to add a new tag

To add a new tag to the Tag Schema:

  
1. Navigate to [**/app/_data/schemas/frontmatter/tags.json**](http://developer.konghq.com/app/_data/schemas/frontmatter/tags.json).  
1. In alphabetical order, add the new tag into the schema list.  
