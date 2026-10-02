// On the page the brand links to, scroll back to the top instead of reloading. Modified and
// non-primary clicks keep their usual behaviour, such as opening a new tab.
export const scrollToTop = event => {
  if (event.defaultPrevented || event.button !== 0) return;
  if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
  const target = new URL(event.currentTarget.href, window.location.href);
  if (target.origin !== window.location.origin || target.pathname !== window.location.pathname) return;

  event.preventDefault();
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  window.scrollTo({ top: 0, behavior: reduced ? "auto" : "smooth" });
  if (window.location.hash) history.replaceState(history.state, "", window.location.pathname + window.location.search);
};
