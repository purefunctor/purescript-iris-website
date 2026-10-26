import type { TransitionBeforePreparationEvent } from "astro:transitions/client";


const pages = new Map<string, Promise<string | null>>();
const modules = new Set<string>();
const parser = new DOMParser();
const linkIntentEvents = ["pointerover", "focusin", "pointerdown"];
const idlePrefetchTimeoutMilliseconds = 2000;
const prefetchDelayWithoutIdleCallbackMilliseconds = 200;

function isDocumentationPage(url: URL) {
  return url.origin === location.origin && url.pathname.startsWith("/docs/");
}

function linkTarget(target: EventTarget | null) {
  const anchor = target instanceof Element ? target.closest("a[href]") : null;
  if (!(anchor instanceof HTMLAnchorElement)) return null;
  if (anchor.target && anchor.target !== "_self") return null;
  if (anchor.hasAttribute("download") || anchor.dataset.astroReload !== undefined) return null;
  const url = new URL(anchor.href);
  return isDocumentationPage(url) ? url : null;
}

function connectionAllowsPrefetching() {
  const connection = (navigator as { connection?: { saveData?: boolean; effectiveType?: string } })
    .connection;
  return !connection?.saveData && !/2g/.test(connection?.effectiveType ?? "");
}

function loadPage(url: URL, priority: RequestPriority) {
  const key = url.pathname + url.search;
  let page = pages.get(key);
  if (page) return page;
  page = fetch(key, { priority })
    .then(async (response) => {
      const type = response.headers.get("content-type") ?? "";
      if (!response.ok || response.redirected || !type.startsWith("text/html")) return null;
      const html = await response.text();
      loadIslands(html);
      return html;
    })
    .catch(() => null);
  pages.set(key, page);
  page.then((html) => html === null && pages.delete(key));
  return page;
}

function loadIslands(html: string) {
  for (const [island] of html.matchAll(/<astro-island\b[^>]*>/g)) {
    for (const [, url] of island.matchAll(/\s(?:component|renderer)-url="([^"]+)"/g)) {
      if (modules.has(url)) continue;
      modules.add(url);
      const script = document.createElement("script");
      script.type = "module";
      script.src = url;
      document.head.append(script);
    }
  }
}

function usesClientRouter(newDocument: Document) {
  return newDocument.querySelector('meta[name="astro-view-transitions-enabled"]') !== null;
}

function stylesheetsAlreadyLoaded(newDocument: Document) {
  for (const link of newDocument.querySelectorAll('head link[rel="stylesheet"]')) {
    const href = CSS.escape(link.getAttribute("href") ?? "");
    if (!document.querySelector(`link[rel="stylesheet"][href="${href}"]`)) return false;
  }
  return true;
}

function prefetchLinks() {
  for (const anchor of document.querySelectorAll("a[href]")) {
    const url = linkTarget(anchor);
    if (url) loadPage(url, "low");
  }
}

function prefetchLinksWhenIdle() {
  if ("requestIdleCallback" in window)
    requestIdleCallback(prefetchLinks, { timeout: idlePrefetchTimeoutMilliseconds });
  else setTimeout(prefetchLinks, prefetchDelayWithoutIdleCallbackMilliseconds);
}

function prepare(event: TransitionBeforePreparationEvent) {
  if (event.formData || !isDocumentationPage(event.to)) return;
  const page = loadPage(event.to, "high");
  const loadDefault = event.loader;
  event.loader = async () => {
    const html = await page;
    if (event.signal.aborted) return;
    const newDocument = html === null ? null : parser.parseFromString(html, "text/html");
    if (newDocument === null) return loadDefault();
    if (!usesClientRouter(newDocument) || !stylesheetsAlreadyLoaded(newDocument)) return loadDefault();
    newDocument.querySelectorAll("noscript").forEach((element) => element.remove());
    event.newDocument = newDocument;
  };
}

export function cacheDocumentationPages() {
  document.addEventListener("astro:before-preparation", (event) =>
    prepare(event as TransitionBeforePreparationEvent),
  );

  if (!connectionAllowsPrefetching()) return;
  document.addEventListener("astro:page-load", prefetchLinksWhenIdle);
  for (const type of linkIntentEvents) {
    document.addEventListener(
      type,
      (event) => {
        const url = linkTarget(event.target);
        if (url) loadPage(url, "high");
      },
      { capture: true, passive: true },
    );
  }
}
