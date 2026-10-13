# Redirects when a page is removed or moved

- A PR that deletes or renames a published page under `app/` (a `.md` file, or a landing page `.yaml`) adds a redirect from the old URL to the new one in `app/_redirects`. Flag a removed or moved page that has no redirect.
- When two or more pages are merged, every old URL redirects to the merged page. Flag any old URL left out.
- A redirect source must not be a live page. Flag a PR that adds or keeps a redirect whose source URL still resolves to a page after the change, for example a new page that reuses an old redirected path.
- If an existing redirect pointed at a page that is now removed, it must be repointed to the final destination. Flag redirect chains (A to B, B to C) that the PR creates or leaves behind.
- Links that point at the old URL are updated to the new one: `related_resources`, `app/_indices/*.yaml`, navigation data, and links in other pages. Flag a changed or remaining reference to a removed URL that the PR could have updated.
- Not a violation: deleting a page that was never published, such as a draft or an auto-generated page, and files under `app/_references/` or `app/_changelogs/`.
