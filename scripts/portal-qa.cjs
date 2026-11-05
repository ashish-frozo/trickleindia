const fs = require("fs");
const { chromium } = require("playwright");
(async () => {
  const b = await chromium.launch({ headless: true, channel: "chrome" });
  const p = await b.newPage({
    viewport: { width: 1440, height: 1000 },
    reducedMotion: "reduce",
  });
  const errors = [];
  p.on("pageerror", (e) => errors.push(String(e)));
  await p.goto(process.env.POP_WEB_URL || "http://localhost:8080");
  await p
    .getByRole("textbox", { name: "Demo access code" })
    .fill(
      fs
        .readFileSync(
          process.env.POP_ACCESS_CODE_FILE || ".local/demo-access-code",
          "utf8",
        )
        .trim(),
    );
  await p.getByRole("button", { name: "Open demo", exact: true }).click();
  await p.getByText("Overview", { exact: true }).first().waitFor();
  await p.waitForTimeout(500);
  await p.screenshot({ path: "output/playwright/W01-en-1440x1000.png" });
  console.log(await p.locator("body").ariaSnapshot());
  await p.setViewportSize({ width: 768, height: 1024 });
  await p.waitForTimeout(500);
  await p.screenshot({ path: "output/playwright/W01-en-768x1024.png" });
  await p.getByRole("button", { name: "हिन्दी", exact: true }).click();
  await p.waitForTimeout(500);
  await p.screenshot({ path: "output/playwright/W01-hi-768x1024.png" });
  await p.setViewportSize({ width: 1440, height: 1000 });
  await p.waitForTimeout(500);
  await p.screenshot({ path: "output/playwright/W01-hi-1440x1000.png" });
  await p.getByRole("button", { name: "English", exact: true }).click();
  let focus = [];
  for (let i = 0; i < 12; i++) {
    await p.keyboard.press("Tab");
    focus.push(
      await p.evaluate(
        () =>
          document.activeElement?.getAttribute("aria-label") ||
          document.activeElement?.textContent?.slice(0, 70),
      ),
    );
  }
  fs.writeFileSync(
    "docs/evidence/web-keyboard.json",
    JSON.stringify({ focus, errors }, null, 2),
  );
  await b.close();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
