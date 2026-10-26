import { useEffect, useRef, useState } from "react";
import { Button } from "react-aria-components/Button";
import { Dialog, DialogTrigger } from "react-aria-components/Dialog";
import { Popover } from "react-aria-components/Popover";
import ChevronDownIcon from "~icons/lucide/chevron-down";
import MenuIcon from "~icons/lucide/menu";
import XIcon from "~icons/lucide/x";
import { NavigationLink } from "#src/Website/Components/NavigationLink.jsx";

const minimumReadingLinePixels = 160;
const scrollPauseMilliseconds = 150;

function useActiveSection(sections) {
  const [active, setActive] = useState(null);
  const ids = sections.map(({ id }) => id).join(" ");

  useEffect(() => {
    const targets = ids.split(" ").filter(Boolean);
    let pinned = null;
    let settle = 0;
    let frame = 0;

    const sectionPastReadingLine = () => {
      const readingLine = Math.max(window.innerHeight / 3, minimumReadingLinePixels);
      const scrolledToEnd = window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2;
      let current = null;
      for (const id of targets) {
        const section = document.getElementById(id);
        if (section && section.getBoundingClientRect().top <= readingLine) current = id;
      }
      return scrolledToEnd && targets.length ? targets[targets.length - 1] : current;
    };
    const scrolledAwayFromLanding = () =>
      pinned?.landed != null && Math.abs(window.scrollY - pinned.landed) > window.innerHeight / 3;
    const update = () => {
      frame = 0;
      if (scrolledAwayFromLanding()) {
        pinned = null;
      }
      setActive(pinned ? pinned.id : sectionPastReadingLine());
    };
    const awaitLanding = () => {
      clearTimeout(settle);
      settle = setTimeout(() => { if (pinned) pinned.landed = window.scrollY; }, scrollPauseMilliseconds);
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

export function navigationBarImpl({ sections, links, pages, classes }) {
  const active = useActiveSection(sections);
  const [menu, setMenu] = useState(null);
  const bar = useRef(null);
  const pagesButton = useRef(null);
  const title = sections.find(({ id }) => id === active)?.title;

  useEffect(() => {
    const closeMenusHiddenByBreakpoint = () => {
      if (getComputedStyle(bar.current).display === "none") setMenu(null);
      else if (getComputedStyle(pagesButton.current).display === "none") {
        setMenu(current => (current === "pages" ? null : current));
      }
    };
    window.addEventListener("resize", closeMenusHiddenByBreakpoint);
    return () => window.removeEventListener("resize", closeMenusHiddenByBreakpoint);
  }, []);

  const trigger = name => ({
    isOpen: menu === name,
    onOpenChange: open => setMenu(open ? name : current => (current === name ? null : current)),
  });
  const closeOnLink = event => {
    if (event.target.closest("a")) setMenu(null);
  };

  return (
    <div className={classes.bar} ref={bar}>
      <DialogTrigger {...trigger("pages")}>
        <Button ref={pagesButton} className={classes.pagesTrigger}>
          {menu === "pages"
            ? <XIcon aria-hidden="true" focusable="false" className={classes.pagesIcon} />
            : <MenuIcon aria-hidden="true" focusable="false" className={classes.pagesIcon} />}
          <span className={classes.label}>Pages</span>
        </Button>
        <Popover
          className={classes.pagesPopover}
          triggerRef={bar}
          placement="bottom start"
          offset={0}
          containerPadding={0}
        >
          <Dialog className={classes.dialog} aria-label="Pages">
            <div onClick={closeOnLink}>{pages}</div>
          </Dialog>
        </Popover>
      </DialogTrigger>
      <DialogTrigger {...trigger("sections")}>
        <Button className={classes.sectionsTrigger}>
          <span className={classes.label}>On this page</span>
          {title && <span className={classes.current}>{title}</span>}
          <ChevronDownIcon aria-hidden="true" focusable="false" className={classes.chevron} />
        </Button>
        <Popover
          className={classes.popover}
          triggerRef={bar}
          placement="bottom start"
          offset={0}
          containerPadding={0}
        >
          <Dialog className={classes.dialog} aria-label="On this page">
            <div onClick={closeOnLink}>
              <SectionLinks sections={sections} active={active} links={links} />
            </div>
          </Dialog>
        </Popover>
      </DialogTrigger>
    </div>
  );
}
