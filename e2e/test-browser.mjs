import { chromium } from "@playwright/test";

console.log("Launching browser...");
const browser = await chromium.launch({
	headless: true,
	args: [
		"--no-sandbox",
		"--disable-setuid-sandbox",
		"--disable-dev-shm-usage",
		"--disable-gpu",
	],
});

console.log("Browser launched successfully");
console.log("Creating page...");
const page = await browser.newPage();
console.log("Page created successfully");

await page.goto("about:blank");
console.log("Navigated to about:blank");

await browser.close();
console.log("Test completed successfully!");
