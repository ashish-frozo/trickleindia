const fs = require("fs"),
  assert = require("assert");
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
  await p.getByRole("button", { name: "Overview Tab 1 of 6", exact: true }).waitFor();
  const session = await p.context().newCDPSession(p);
  await session.send("Emulation.setEmulatedVisionDeficiency", {
    type: "achromatopsia",
  });
  await p.waitForTimeout(500);
  await p.screenshot({
    path: "output/playwright/W01-en-1440x1000-grayscale.png",
  });
  const reducedMotion = await p.evaluate(
    () => matchMedia("(prefers-reduced-motion: reduce)").matches,
  );
  assert(reducedMotion);
  const focus = [];
  let activatedSupport = false;
  for (let i = 0; i < 45; i++) {
    await p.keyboard.press("Tab");
    await p.waitForTimeout(60);
    const label = await p.evaluate(
      () =>
        document.activeElement?.getAttribute("aria-label") ||
        document.activeElement?.textContent?.slice(0, 100) ||
        "",
    );
    focus.push(label);
    if (label.includes("Support") && label.includes("Tab 4")) {
      await p.keyboard.press("Enter");
      await p.waitForTimeout(500);
      activatedSupport = (await p.locator("body").ariaSnapshot()).includes(
        "Request status",
      );
      if (activatedSupport) break;
    }
  }
  assert(activatedSupport, "Support navigation did not activate from keyboard");
  assert.equal(errors.length, 0);
  fs.writeFileSync(
    "docs/evidence/web-keyboard.json",
    JSON.stringify(
      {
        focus,
        activatedSupport,
        reducedMotion,
        grayscale: "Chrome achromatopsia vision emulation",
        errors,
      },
      null,
      2,
    ),
  );
  await b.close();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
