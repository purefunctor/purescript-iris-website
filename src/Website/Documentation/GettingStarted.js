export const configurePlatform = () => {
  if (/^Mac|^macOS/.test(navigator.platform)) {
    document.documentElement.setAttribute("data-landing-macos", "");
  }
  return () => {};
};
