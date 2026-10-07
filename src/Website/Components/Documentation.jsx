import { useEffect, useRef, useState } from "react";
import { Button, Dialog, Modal, ModalOverlay } from "react-aria-components";
import MenuIcon from "~icons/lucide/menu";
import CloseIcon from "~icons/lucide/x";
import { createNavigationOcean } from "#src/Website/Components/NavigationOcean.js";

export function navigationLinkImpl({ href, className, canvasClassName, contentClassName, current, content }) {
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
      aria-current={current ? "page" : undefined}
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
      <span className={contentClassName}>{content}</span>
    </a>
  );
}

export function mobileSidebarImpl({
  rootClassName, triggerClassName, overlayClassName, modalClassName,
  dialogClassName, headClassName, titleClassName, closeClassName, navigation,
}) {
  const [open, setOpen] = useState(false);
  const root = useRef(null);

  useEffect(() => {
    // Let the shared StyleX breakpoint remain the source of truth.
    const resize = () => {
      if (getComputedStyle(root.current).display === "none") setOpen(false);
    };
    window.addEventListener("resize", resize);
    return () => window.removeEventListener("resize", resize);
  }, []);

  return (
    <div className={rootClassName} ref={root}>
      <Button
        id="documentation-sidebar-toggle"
        className={triggerClassName}
        aria-label="Open documentation sidebar"
        aria-expanded={open}
        aria-controls="documentation-sidebar"
        onPress={() => setOpen(true)}
      >
        <MenuIcon aria-hidden="true" focusable="false" />
      </Button>
      <ModalOverlay className={overlayClassName} isOpen={open} onOpenChange={setOpen} isDismissable>
        <Modal className={modalClassName}>
          <Dialog id="documentation-sidebar" className={dialogClassName} aria-labelledby="documentation-sidebar-title">
            <div className={headClassName}>
              <h2 id="documentation-sidebar-title" className={titleClassName}>Documentation</h2>
              <Button className={closeClassName} aria-label="Close documentation sidebar" onPress={() => setOpen(false)}>
                <CloseIcon aria-hidden="true" focusable="false" />
              </Button>
            </div>
            <nav aria-label="Documentation" onClick={event => {
              if (event.target.closest("a")) setOpen(false);
            }}>
              {navigation}
            </nav>
          </Dialog>
        </Modal>
      </ModalOverlay>
    </div>
  );
}
