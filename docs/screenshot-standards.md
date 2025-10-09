# Screenshot standards

Use this page to capture clear, consistent screenshots that stay accurate and easy to maintain.

| Question | Answer |
| :---- | :---- |
| What size should I use? | 1500 × 845 |
| Where do I save files? | `app/_assets/images/docs/...` (lowercase-with-dashes filenames). |
| How do I name files? | `product-version-feature-goal.png`. For example, `konnect-v2-1-dev-portal-menu.png`. |
| Can I use screenshots in how-to guides? | Yes, only when text is insufficient; otherwise use a small, focused screenshot or a wireframe. |
| What can’t I screenshot? | Third-party UIs, real customer data/PII, volatile content, or anything that harms performance or localization. |
| What is shot-scraper? | A Playwright-based CLI that automates repeatable screenshots for documents. |

## Capture standards

Before including screenshots, write the document first. Add a screenshot only when words are not enough to explain the state, layout, or focus. Prefer a small, cropped image over a full-screen capture. For conceptual layouts, use a simple wireframe instead.

Use the following capture checklist to include a screenshot into a document:
- [ ] Capture with **shotscraper**  
- [ ] Set resolution to **1500 × 845**  
- [ ] Crop to the relevant panel; omit the cursor  
- [ ] If needed, add a thin rectangular highlight in #0788ad; avoid heavy annotations  
- [ ] Apply the `image-border` class when a surrounding border improves contrast  
- [ ] Save images at **≤2 MB**; do not use GIFs  
- [ ] Store files in `app/_assets/images/docs/...` with lowercase, hyphenated names

## Shotscraper screenshot workflow

Ensure that you have shotscraper already downloaded and installed onto your editor. To download shotscraper, go to the [README](https://github.com/Kong/developer.konghq.com/blob/main/tools/screenshots/README.md). Once you have Shotscraper downloaded, complete the following process to capture and include a screenshot:
1. Take a screenshot of the target page
The following saves a full-page screenshot as contributing.png in your current directory:
```sh
shot-scraper https://developer.konghq.com/contributing/ -o contributing.png
```
2. (Optional) Capture only a section
If you want just a specific element, add a CSS selector:
```sh
shot-scraper https://developer.konghq.com/contributing/ -o contributing-section.png --selector "main"
```
3. Open the image in Visual Studio Code
    - Launch VS Code
    - Select **File → Open File…** 
    - Select `contributing.png.`
    - (Optional) Install the free extension Image Preview if you want inline image editing and annotations.
4. Edit or annotate
    - In VS Code, right-click the image to open it with your default editor (Paint, GIMP, or Photoshop).
    - Save your changes back to the same file or to a new filename. For example, `contributing-annotated.png.`.
5. Commit the screenshot
Add the new screenshot to your docs repo:
```sh
git add contributing-annotated.png
git commit -m "Add screenshot of Contributing page"
```
6. Use the image in documentation
Insert the screenshot with standard Markdown:
```sh
![Contributing page screenshot](./contributing-annotated.png)
```

## Text and image flow

**Introduce → show → explain**: captions are optional but alt text is **required**. Write a lead sentence that sets context and ends with a colon, then the image, and then alt text.  
**Why:** Keeps narrative coherent and images purposeful; supports accessibility and localization.  

| Do | Don't |
| :---- | :---- |
| Write: “From the **Menu** tab, click **Add menu item:**” | Drop a screenshot without introduction: ![Add menu](/assets/images/docs/add-menu.png) |
