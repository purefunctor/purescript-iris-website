import { useEffect, useRef, useState } from "react";
import { Button, Dialog, DialogTrigger, Modal, ModalOverlay, Popover } from "react-aria-components";
import ChevronDownIcon from "~icons/lucide/chevron-down";
import PanelLeftCloseIcon from "~icons/lucide/panel-left-close";
import PanelLeftOpenIcon from "~icons/lucide/panel-left-open";
import { NavigationLink } from "#src/Website/Components/NavigationLink.jsx";

export const configurePlatform = () => {
  if (/^Mac|^macOS/.test(navigator.platform)) {
    document.documentElement.setAttribute("data-landing-macos", "");
  }
  return () => {};
};

// When the page links scroll horizontally on narrow screens, keep the current page in view and
// mark the edges that hide links so they can fade.
export function pageNavigationImpl({ className, label, content }) {
  const navigation = useRef(null);
  const [fade, setFade] = useState(undefined);

  useEffect(() => {
    const element = navigation.current;
    const current = element.querySelector("[aria-current='page']");
    if (current && current.offsetLeft + current.offsetWidth > element.clientWidth) {
      element.scrollLeft = current.offsetLeft;
    }
    const update = () => {
      const start = element.scrollLeft > 1;
      const end = element.scrollLeft + element.clientWidth < element.scrollWidth - 1;
      setFade(start && end ? "both" : start ? "start" : end ? "end" : undefined);
    };
    update();
    element.addEventListener("scroll", update, { passive: true });
    window.addEventListener("resize", update);
    return () => {
      element.removeEventListener("scroll", update);
      window.removeEventListener("resize", update);
    };
  }, []);

  return <nav ref={navigation} className={className} aria-label={label} data-fade={fade}>{content}</nav>;
}

// The reader is in the last section whose top has passed a line a third of the way down the
// viewport, or in the last section once the page cannot scroll further. A section the reader
// jumps to stays current until they scroll a third of the viewport away from where the jump
// landed, so short sections below it cannot take over.
function useActiveSection(sections) {
  const [active, setActive] = useState(null);
  const ids = sections.map(({ id }) => id).join(" ");

  useEffect(() => {
    const targets = ids.split(" ").filter(Boolean);
    let pinned = null;
    let settle = 0;
    let frame = 0;

    const spy = () => {
      const line = Math.max(window.innerHeight / 3, 160);
      const end = window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2;
      let current = null;
      for (const id of targets) {
        const section = document.getElementById(id);
        if (section && section.getBoundingClientRect().top <= line) current = id;
      }
      return end && targets.length ? targets[targets.length - 1] : current;
    };
    const update = () => {
      frame = 0;
      if (pinned?.landed != null && Math.abs(window.scrollY - pinned.landed) > window.innerHeight / 3) {
        pinned = null;
      }
      setActive(pinned ? pinned.id : spy());
    };
    // The jump has landed once scrolling has paused, including when it did not scroll at all.
    const awaitLanding = () => {
      clearTimeout(settle);
      settle = setTimeout(() => { if (pinned) pinned.landed = window.scrollY; }, 150);
    };
    const pin = hash => {
      const id = decodeURIComponent(hash.slice(1));
      if (!targets.includes(id)) return;
      pinned = { id, landed: null };
      awaitLanding();
      setActive(id);
    };
    const scroll = () => {
      if (pinned && pinned.landed == null) awaitLanding();
      if (!frame) frame = requestAnimationFrame(update);
    };
    const resize = () => { if (!frame) frame = requestAnimationFrame(update); };
    const click = event => {
      const link = event.target.closest?.("a[href^='#']");
      if (link) pin(link.getAttribute("href"));
    };
    const hashchange = () => pin(window.location.hash);

    if (window.location.hash) pin(window.location.hash);
    update();
    window.addEventListener("scroll", scroll, { passive: true });
    window.addEventListener("resize", resize);
    window.addEventListener("hashchange", hashchange);
    document.addEventListener("click", click);
    return () => {
      cancelAnimationFrame(frame);
      clearTimeout(settle);
      window.removeEventListener("scroll", scroll);
      window.removeEventListener("resize", resize);
      window.removeEventListener("hashchange", hashchange);
      document.removeEventListener("click", click);
    };
  }, [ids]);

  return active;
}

function SectionLinks({ sections, active, links }) {
  return (
    <div className={links.listClassName}>
      {sections.map(({ id, title }) => (
        <NavigationLink
          key={id}
          href={`#${id}`}
          className={id === active ? links.currentClassName : links.className}
          canvasClassName={links.canvasClassName}
          contentClassName={links.contentClassName}
          ariaCurrent={id === active ? "location" : undefined}
        >
          {title}
        </NavigationLink>
      ))}
    </div>
  );
}

export function sectionNavigationImpl({ sections, links }) {
  const active = useActiveSection(sections);
  return <SectionLinks sections={sections} active={active} links={links} />;
}

// Close an overlay when a shared StyleX breakpoint hides the component that opened it.
function useCloseWhenHidden(setOpen) {
  const root = useRef(null);

  useEffect(() => {
    const resize = () => {
      if (getComputedStyle(root.current).display === "none") setOpen(false);
    };
    window.addEventListener("resize", resize);
    return () => window.removeEventListener("resize", resize);
  }, []);

  return root;
}

export function sectionMenuImpl({
  sections, links, rootClassName, triggerClassName, labelClassName, currentClassName,
  iconClassName, popoverClassName, dialogClassName, headingClassName, resources,
}) {
  const active = useActiveSection(sections);
  const [open, setOpen] = useState(false);
  const root = useCloseWhenHidden(setOpen);
  const title = sections.find(({ id }) => id === active)?.title;

  return (
    <div className={rootClassName} ref={root}>
      <DialogTrigger isOpen={open} onOpenChange={setOpen}>
        <Button className={triggerClassName}>
          <span className={labelClassName}>On this page</span>
          {title && <span className={currentClassName}>{title}</span>}
          <ChevronDownIcon aria-hidden="true" focusable="false" className={iconClassName} />
        </Button>
        <Popover className={popoverClassName} placement="bottom start" offset={0} containerPadding={0}>
          <Dialog className={dialogClassName} aria-label="On this page">
            <div onClick={event => {
              if (event.target.closest("a")) setOpen(false);
            }}>
              <SectionLinks sections={sections} active={active} links={links} />
              <p className={headingClassName}>Resources</p>
              {resources}
            </div>
          </Dialog>
        </Popover>
      </DialogTrigger>
    </div>
  );
}

export function sectionSidebarImpl({
  sections, links, rootClassName, buttonClassName, closeClassName, overlayClassName,
  panelClassName, dialogClassName, labelClassName, resources,
}) {
  const active = useActiveSection(sections);
  const [open, setOpen] = useState(false);
  const root = useCloseWhenHidden(setOpen);

  return (
    <div className={rootClassName} ref={root}>
      <Button
        className={buttonClassName}
        aria-label="Expand sidebar"
        aria-expanded={open}
        aria-controls="documentation-sidebar"
        onPress={() => setOpen(true)}
      >
        <PanelLeftOpenIcon aria-hidden="true" focusable="false" />
      </Button>
      <ModalOverlay className={overlayClassName} isOpen={open} onOpenChange={setOpen} isDismissable>
        <Modal className={panelClassName}>
          <Dialog id="documentation-sidebar" className={dialogClassName} aria-label="Documentation sidebar">
            <Button className={closeClassName} aria-label="Collapse sidebar" onPress={() => setOpen(false)}>
              <PanelLeftCloseIcon aria-hidden="true" focusable="false" />
            </Button>
            <nav aria-label="On this page" onClick={event => {
              if (event.target.closest("a")) setOpen(false);
            }}>
              <p className={labelClassName}>On this page</p>
              <SectionLinks sections={sections} active={active} links={links} />
            </nav>
            <p className={labelClassName}>Resources</p>
            {resources}
          </Dialog>
        </Modal>
      </ModalOverlay>
    </div>
  );
}
