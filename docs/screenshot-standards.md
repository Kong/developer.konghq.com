# Screenshot standards


## Capture standards

Use the following capture checklist to include a screenshot into a document:
- [ ] Capture with **shotscraper**  
- [ ] Set resolution to **1500 × 845**  
- [ ] Crop to the relevant panel; omit the cursor  
- [ ] If needed, add a thin rectangular highlight in #0788ad; avoid annotations  


### FAQ

| Question | Answer |
| :---- | :---- |
| What size should I use? | 1500 × 845 |
| Where do I save files? | `app/assets/images/...` (lowercase-with-dashes filenames). |
| How do I name files? | `product-version-feature-goal.png`. For example, `konnect-v2-1-dev-portal-menu.png`. |
| Can I use screenshots in how-to guides? | Yes, only when text is insufficient. |
| What can’t I screenshot? | Third-party UIs, real customer data/PII, volatile content, or anything that harms performance or localization. |


- [ ] do not use GIFs  
- [ ] Store files in `app/assets/images/...` with lowercase, hyphenated names

## Shotscraper
Use [shotscraper](https://github.com/Kong/developer.konghq.com/tree/main/tools/screenshots) to automate screenshot creation. 

## Text and image flow

**Introduce → show → explain**: captions are optional but alt text is **required**. Write a lead sentence that sets context and ends with a colon, then the image, and then alt text.  
**Why:** Keeps narrative coherent and images purposeful; supports accessibility and localization.  

| Do | Don't |
| :---- | :---- |
| Write: “From the **Menu** tab, click **Add menu item:**” | Drop a screenshot without introduction: ![Add menu](/assets/images/docs/add-menu.png) |
