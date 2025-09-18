# Screenshot standards

**Rule**: Write the doc first. Add screenshots only when text is insufficient; otherwise use wireframes. Follow strict capture standards for quality, consistency, and maintainability.

**Why:** Screenshots get stale; consistent, lightweight assets improve performance and accessibility.

**Automation:** Use **shot-scraper** to keep screenshots reproducible and fresh.

**Capture rules (required):**

- [ ] Take screenshots with browser dev tools.  
- [ ] Set resolution **1500×845**.  
- [ ] Crop to the relevant panel; no cursor.  
- [ ] Draw a rectangular border around the focal area using brand accent **\#0788ad**.  
- [ ] Use the `image-border` class if you need a surrounding border for contrast.  
- [ ] Avoid GIFs; keep files \~**≤2 MB**.  
- [ ] File path: `app/_assets/images/docs/...`; file names **lowercase-with-dashes**.

**Do:** Add a screenshot only when the UI is complex to describe.

**Don’t:** Replace clear instructions with a screenshot, or ignore file-naming conventions.

**Example:** In [Kong Mesh user interface (GUI)](https://developer.konghq.com/mesh/kuma-user-interface-gui/), there are images showing the menu panels and tabs. They are cropped to the relevant sidebar, labels match UI, and placed in a way that supports the text description.

**Markdown examples:**

```
![Gateway Service panel](/assets/images/docs/gateway/service-panel.png){:.image-border}
```

or

```html
<center>
<img src="/assets/images/gui/overview.png" alt="A screenshot of the Mesh Overview of the Kuma GUI" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>
```

## Text and image flow

**Rule:** **Introduce → show → explain**; captions are optional but alt text is **required**.  
**What:** Write a lead sentence that sets context and ends with a colon, then the image, and then alt text.  
**Why:** Keeps narrative coherent and images purposeful; supports accessibility and localization.  
**Do:** Provide informative alt text that describes the action-relevant region.

**Don’t:** Use generic “screenshot” alt text or drop an image without an introduction.

**Example:** “Alt: Dev Portal **Customization** page with **Menu** tab and **Add menu item** button.”

## File naming, versioning, and accessibility

**Rule:** Use predictable names; reflect keyboard-navigable labels.  
**What:** `product-version-feature-goal.png`; alt explains the action-relevant area.  
**Why:** Improves searchability, swap-outs, and translation.  
**Do:** `konnect-v2-1-dev-portal-menu.png`; “Alt: Menu tab showing Add menu item.”

**Don’t:** `IMG_1234.PNG`; “Alt: screenshot.”

## Legal and privacy

**Rule:** Never expose real data; use realistic fakes and consistent redaction. For example, ACME accounts.  
**What:** Example domains, seeded UUIDs, redaction that preserves legibility.  
**Why:** Protects confidentiality and compliance while keeping the UI intelligible.  
**How:** Maintain a shared pool of example values; apply the same redaction style everywhere.

# Accessibility & inclusivity

**Rule:** Construct documentation to include all users. Make docs accessible and globally understandable by:

* including descriptive alt text for images  
* avoiding idioms  
* ensuring keyboard navigation is describable

**Why:** Some readers use assistive tech or translation; idioms do not translate; keyboard users follow focus order and labels.

**Do:** Write: *Alt text: “Mesh Overview showing tabs for Services, Policies, Data-planes”* for a screenshot.

**Don’t:**
* Leave alt text blank or generic (“screenshot”).  
* Use idioms (“flip the switch”, “fires when ready”) that may confuse non-native speakers.

**Example:** In *Kong Mesh user interface (GUI)* docs, the text describes that you can select entities, view stats, tabs for services or policies, etc.; screenshots include descriptive captions. [Kong Docs](https://developer.konghq.com/mesh/kuma-user-interface-gui/)
