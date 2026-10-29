import { test, expect } from "@playwright/test";
import { buildIconMap } from "../tools/pele-icons/generate.mjs";

test.describe("diagram rendering", () => {
  test("icon map only holds referenced icons, sized for labels, without root ids", () => {
    const icons = buildIconMap();

    expect(Object.keys(icons)).toContain("database");
    expect(Object.keys(icons)).toContain("gateway");
    expect(icons.database).toContain('width="20"');
    expect(icons.database).toContain('height="20"');
    expect(icons.gateway).toContain('width="20"');
    expect(icons["1password"]).toBeUndefined();
    expect(icons.database).not.toMatch(/^<svg[^>]*\bid=/);
  });

  test("icon markup cannot leak global styles or unwanted strokes into the page", () => {
    const icons = buildIconMap();

    for (const [name, markup] of Object.entries(icons)) {
      expect(markup, name).not.toMatch(/<style/i);
      expect(markup, name).not.toMatch(/<script/i);
      expect(markup, name).toMatch(/^<svg[^>]*\bstroke="none"/);
    }
  });

  test("flowchart page renders its diagrams through Pele", async ({ page }) => {
    await page.goto("/gateway/hybrid-mode/");

    await expect(page.locator("pre.mermaid svg.pele").first()).toBeVisible();
    await expect(page.locator("pre.mermaid .pele-error")).toHaveCount(0);
  });

  test("sequence page renders its diagrams through Pele", async ({ page }) => {
    await page.goto("/gateway/entities/route/");

    await expect(page.locator("pre.mermaid svg.pele").first()).toBeVisible();
    await expect(page.locator("pre.mermaid .pele-error")).toHaveCount(0);
  });

  test("fa:fa- icon tokens resolve to inline SVG icons", async ({ page }) => {
    await page.goto("/insomnia/storage/");

    const diagram = page.locator("pre.mermaid").first();
    await expect(diagram.locator("svg.pele")).toBeVisible();
    await expect(
      diagram.locator('svg.pele-icon[data-icon="fa:fa-database"]'),
    ).toBeVisible();
    await expect(diagram).not.toContainText("fa:fa-");
    await expect(diagram.locator("img")).toHaveCount(0);
  });

  test("inlined icon markup cannot restyle every svg on the page", async ({
    page,
  }) => {
    await page.goto("/plugins/degraphql/");

    const diagram = page.locator("pre.mermaid").first();
    await expect(diagram.locator("svg.pele")).toBeVisible();
    await expect(
      diagram.locator('svg.pele-icon[data-icon="fa:fa-graphql"]'),
    ).toBeVisible();
    await expect(diagram.locator("style")).toHaveCount(0);
  });

  test("diagrams follow the theme without re-rendering", async ({ page }) => {
    await page.goto("/gateway/hybrid-mode/");

    const svg = page.locator("pre.mermaid svg.pele").first();
    await expect(svg).toBeVisible();
    await svg.evaluate((el) => el.setAttribute("data-same-node", "yes"));

    const lightFill = await svg
      .locator("text")
      .first()
      .evaluate((el) => getComputedStyle(el).fill);

    await page.evaluate(() => document.documentElement.classList.add("dark"));

    await expect(page.locator("[data-same-node='yes']")).toBeVisible();
    const darkFill = await page
      .locator("[data-same-node='yes'] text")
      .first()
      .evaluate((el) => getComputedStyle(el).fill);

    expect(darkFill).not.toBe(lightFill);

    await page.evaluate(() =>
      document.documentElement.classList.remove("dark"),
    );
  });

  test("diagram source with frontmatter at a nonzero offset still renders", async ({
    page,
  }) => {
    await page.goto("/mesh/disaster-recovery/");

    await expect(page.locator("pre.mermaid svg.pele").first()).toBeVisible();
    await expect(page.locator("pre.mermaid .pele-error")).toHaveCount(0);
  });

  test("HTML entities in sequence messages decode and render as angle brackets", async ({
    page,
  }) => {
    await page.goto("/konnect-platform/entra-saml-sso/");

    const diagram = page
      .locator("pre.mermaid")
      .filter({ hasText: "<custom_path>" });
    await expect(diagram).toHaveCount(1);
    await expect(diagram.locator(".pele-error")).toHaveCount(0);
    await expect(diagram).toContainText("<tenant_id>");
    await expect(diagram).toContainText("<organization_id>");
  });

  test("sequence messages with Bearer <apiKey> render", async ({ page }) => {
    await page.goto("/cookbooks/github-copilot-byok/");

    const diagram = page.locator("pre.mermaid").filter({ hasText: "<apiKey>" });
    await expect(diagram).toHaveCount(1);
    await expect(diagram.locator(".pele-error")).toHaveCount(0);
  });

  test("a diagram with invalid syntax shows an inline error and the page survives", async ({
    page,
  }) => {
    await page.route("/gateway/hybrid-mode/", async (route) => {
      const response = await route.fetch();
      const body = await response.text();
      await route.fulfill({
        response,
        body: body.replace(
          "</body>",
          '<pre class="mermaid" id="broken-diagram">this is not a diagram at all</pre></body>',
        ),
      });
    });
    await page.goto("/gateway/hybrid-mode/");

    const broken = page.locator("#broken-diagram");
    await expect(broken.locator(".pele-error")).toBeVisible();
    await expect(
      page.locator("pre.mermaid svg.pele").first(),
    ).toBeVisible();
    await expect(page.locator("h1")).toBeVisible();
  });

  test("doubly-escaped entities in flowchart labels decode and render", async ({
    page,
  }) => {
    await page.goto(
      "/kubernetes-ingress-controller/deployment-topologies/db-backed/",
    );

    const diagram = page
      .locator("pre.mermaid")
      .filter({ hasText: "(Active)" });
    await expect(diagram).toHaveCount(2);
    await expect(page.locator("pre.mermaid .pele-error")).toHaveCount(0);
    await expect(diagram.first()).toContainText("(Standby)");
  });
});
