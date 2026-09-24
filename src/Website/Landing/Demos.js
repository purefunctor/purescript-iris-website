export const createVideoPreloader = (slugs) => () => {
  const urls = new Map();
  const controller = new AbortController();
  const queue = [...slugs];
  let disposed = false;

  const preload = async () => {
    while (!disposed && queue.length) {
      const slug = queue.shift();
      try {
        const response = await fetch(`/editor-demos/${slug}.mp4`, { signal: controller.signal });
        if (!response.ok) continue;
        const blob = await response.blob();
        if (!disposed) urls.set(slug, URL.createObjectURL(blob));
      } catch {
        // A failed preload falls back to the regular video URL when selected.
      }
    }
  };
  const start = () => {
    if (navigator.connection?.saveData) return;
    for (let i = 0; i < 3; i++) void preload();
  };

  if (document.readyState === "complete") start();
  else window.addEventListener("load", start, { once: true });

  return {
    urls,
    dispose: () => {
      disposed = true;
      window.removeEventListener("load", start);
      controller.abort();
      for (const url of urls.values()) URL.revokeObjectURL(url);
    },
  };
};

export const videoSource = (preloader) => (slug) => () =>
  preloader.urls.get(slug) ?? `/editor-demos/${slug}.mp4`;

export const disposeVideoPreloader = (preloader) => () => preloader.dispose();
