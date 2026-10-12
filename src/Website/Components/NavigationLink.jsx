import { useEffect, useRef } from "react";
import { createNavigationOcean } from "#src/Website/Components/NavigationOcean.js";

// Fade the site's ocean in behind the link while it is hovered or focused, and pulse it on press.
export function NavigationLink({ href, className, canvasClassName, contentClassName, ariaCurrent, children }) {
  const canvas = useRef(null);
  const field = useRef(null);
  const interaction = useRef({ hovered: false, focused: false });

  useEffect(() => () => { field.current?.stop(); field.current = null; }, []);

  const setInteraction = (name, value) => {
    interaction.current[name] = value;
    if (value) field.current ??= createNavigationOcean(canvas.current);
    field.current?.setActive(interaction.current.hovered || interaction.current.focused);
  };
  const pulse = () => {
    field.current ??= createNavigationOcean(canvas.current);
    field.current.pulse();
  };

  return (
    <a
      href={href}
      className={className}
      aria-current={ariaCurrent}
      onPointerEnter={event => {
        if (event.pointerType !== "touch") setInteraction("hovered", true);
      }}
      onPointerLeave={() => setInteraction("hovered", false)}
      onPointerDown={pulse}
      onFocus={event => setInteraction("focused", event.currentTarget.matches(":focus-visible"))}
      onBlur={() => setInteraction("focused", false)}
      onClick={event => { if (event.detail === 0) pulse(); }}
    >
      <canvas ref={canvas} aria-hidden="true" className={canvasClassName} />
      <span className={contentClassName}>{children}</span>
    </a>
  );
}

export function navigationLinkImpl({ current, content, ...link }) {
  return <NavigationLink {...link} ariaCurrent={current ? "page" : undefined}>{content}</NavigationLink>;
}
