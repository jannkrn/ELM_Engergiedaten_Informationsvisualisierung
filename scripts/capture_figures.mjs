import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";

const port = Number(process.env.CDP_PORT || 9223);
const targetUrl = process.env.APP_URL || "http://127.0.0.1:8765/";
const outputDirectory = process.env.FIGURE_DIR || path.resolve("experiments", "figures", "final");

class CdpClient {
  constructor(url) {
    this.nextId = 1;
    this.pending = new Map();
    this.socket = new WebSocket(url);
  }

  async open() {
    await new Promise((resolve, reject) => {
      this.socket.addEventListener("open", resolve, { once: true });
      this.socket.addEventListener("error", reject, { once: true });
    });
    this.socket.addEventListener("message", (event) => {
      const message = JSON.parse(event.data);
      if (!message.id) return;
      const pending = this.pending.get(message.id);
      if (!pending) return;
      this.pending.delete(message.id);
      if (message.error) pending.reject(new Error(message.error.message));
      else pending.resolve(message.result);
    });
  }

  send(method, params = {}) {
    const id = this.nextId++;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.socket.send(JSON.stringify({ id, method, params }));
    });
  }

  close() {
    this.socket.close();
  }
}

async function evaluate(client, expression) {
  const result = await client.send("Runtime.evaluate", {
    expression,
    awaitPromise: true,
    returnByValue: true,
  });
  if (result.exceptionDetails) throw new Error(result.exceptionDetails.text);
  return result.result.value;
}

async function waitUntil(client, expression, timeoutMs = 15000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    if (await evaluate(client, expression)) return;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error(`Zeitüberschreitung beim Warten auf: ${expression}`);
}

async function clickButton(client, label) {
  const clicked = await evaluate(
    client,
    `(() => {
      const button = [...document.querySelectorAll('button')].find((element) => element.textContent.trim() === ${JSON.stringify(label)});
      if (!button) return false;
      button.click();
      return true;
    })()`,
  );
  if (!clicked) throw new Error(`Schaltfläche nicht gefunden: ${label}`);
}

async function clickNetworkCountry(client, country) {
  const clicked = await evaluate(
    client,
    `(() => {
      const label = [...document.querySelectorAll('#flow-view text')].find((element) => element.textContent.trim() === ${JSON.stringify(country)});
      if (!label) return false;
      label.parentElement.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      return true;
    })()`,
  );
  if (!clicked) throw new Error(`Land nicht gefunden: ${country}`);
}

async function clickTime(client, label) {
  const clicked = await evaluate(
    client,
    `(() => {
      const title = [...document.querySelectorAll('#timeline-view title')].find((element) => element.textContent.startsWith(${JSON.stringify(label)}) && element.textContent.includes('Gesamt:'));
      const hit = title?.parentElement?.querySelector('rect');
      if (!hit) return false;
      hit.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      return true;
    })()`,
  );
  if (!clicked) throw new Error(`Zeitpunkt nicht gefunden: ${label}`);
}

async function clickMatrixCell(client, country, label) {
  const prefix = `${country} · ${label}`;
  const clicked = await evaluate(
    client,
    `(() => {
      const title = [...document.querySelectorAll('#matrix-view title')].find((element) => element.textContent.startsWith(${JSON.stringify(prefix)}));
      const cell = title?.parentElement;
      if (!cell) return false;
      cell.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      return true;
    })()`,
  );
  if (!clicked) throw new Error(`Matrixzelle nicht gefunden: ${prefix}`);
}

async function capture(client, filename, selector) {
  const clip = await evaluate(
    client,
    `(() => {
      const element = document.querySelector(${JSON.stringify(selector)});
      if (!element) return null;
      const box = element.getBoundingClientRect();
      return { x: box.left + scrollX, y: box.top + scrollY, width: box.width, height: box.height };
    })()`,
  );
  if (!clip) throw new Error(`Element nicht gefunden: ${selector}`);
  const result = await client.send("Page.captureScreenshot", {
    format: "png",
    fromSurface: true,
    captureBeyondViewport: true,
    clip: { ...clip, scale: 1.5 },
  });
  await writeFile(path.join(outputDirectory, filename), Buffer.from(result.data, "base64"));
}

async function reload(client) {
  await client.send("Page.navigate", { url: targetUrl });
  await waitUntil(client, "document.readyState === 'complete' && document.querySelectorAll('#matrix-view rect').length > 100");
}

async function main() {
  await mkdir(outputDirectory, { recursive: true });
  const page = await fetch(`http://127.0.0.1:${port}/json/new?${encodeURIComponent("about:blank")}`, { method: "PUT" }).then((response) => response.json());
  const client = new CdpClient(page.webSocketDebuggerUrl);
  await client.open();
  await client.send("Page.enable");
  await client.send("Runtime.enable");
  await client.send("Emulation.setDeviceMetricsOverride", {
    width: 1440,
    height: 1100,
    deviceScaleFactor: 1,
    mobile: false,
  });

  await reload(client);
  await capture(client, "01_uebersicht.png", ".app-shell");

  await clickNetworkCountry(client, "France");
  await waitUntil(client, "document.body.innerText.includes('Auswahl: France')");
  await capture(client, "02_frankreich_netzwerk.png", "#flow-view");

  await clickButton(client, "nächster Zeitraum →");
  await waitUntil(client, "document.body.innerText.includes('Ansicht: 08.05. 00 h – 14.05. 23 h')");
  await clickTime(client, "11.05. 11 h");
  await waitUntil(client, "document.body.innerText.includes('Auswahl: France · 11.05. 11 h')");
  await capture(client, "03_negativpreis_zeitreihe.png", "#timeline-view");

  await reload(client);
  await clickButton(client, "48 Stunden");
  await clickButton(client, "nächster Zeitraum →");
  await waitUntil(client, "document.body.innerText.includes('Ansicht: 03.05. 00 h – 04.05. 23 h')");
  await clickMatrixCell(client, "Denmark", "03.05. 12 h");
  await waitUntil(client, "document.body.innerText.includes('Auswahl: Denmark · 03.05. 12 h')");
  await capture(client, "04_daenemark_matrix.png", "#matrix-view");

  console.log(`Vier Abbildungen nach ${outputDirectory} geschrieben.`);
  client.close();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
