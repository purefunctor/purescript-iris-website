const seekStep = 2;

export const prefersReducedMotion = () => window.matchMedia("(prefers-reduced-motion: reduce)").matches;

export const formatTime = seconds => {
  const whole = Math.floor(seconds || 0);
  return `${Math.floor(whole / 60)}:${String(whole % 60).padStart(2, "0")}`;
};

export const wholeSeconds = seconds => Math.floor(seconds || 0);

export const setPlayback = videoRef => shouldPlay => () => {
  const video = videoRef.current;
  if (!video) return;
  if (shouldPlay) video.play().catch(() => {});
  else video.pause();
};

// iPhone Safari only supports native fullscreen on the video element itself.
export const toggleFullscreen = ({ frame: frameRef, video: videoRef }) => () => {
  if (document.fullscreenElement) {
    document.exitFullscreen().catch(() => {});
    return;
  }
  const frame = frameRef.current;
  if (frame?.requestFullscreen) frame.requestFullscreen().catch(() => {});
  else videoRef.current?.webkitEnterFullscreen?.();
};

// Media events, fullscreen changes, visibility and the seek bar's pointer and keyboard input.
// Positions are written as CSS variables on the seek bar so seeking does not re-render.
export const observePlayer = ({
  bubble: bubbleRef,
  frame: frameRef,
  onEnded,
  onFullscreen,
  onTime,
  onToggle,
  onVisible,
  slider: sliderRef,
  video: videoRef,
}) => () => {
  const bubble = bubbleRef.current;
  const frame = frameRef.current;
  const slider = sliderRef.current;
  const video = videoRef.current;
  if (!bubble || !frame || !slider || !video) return () => {};

  const duration = () => (Number.isFinite(video.duration) ? video.duration : 0);
  const point = fraction => {
    slider.style.setProperty("--seek-pointer", fraction);
    bubble.textContent = formatTime(fraction * duration());
  };
  const update = () => {
    const total = duration();
    const fraction = total ? video.currentTime / total : 0;
    slider.style.setProperty("--seek-progress", fraction);
    if (slider.hasAttribute("data-seeking") || document.activeElement === slider) point(fraction);
    onTime(video.currentTime)(total)();
  };
  const ended = () => onEnded();
  const fullscreenChange = () => onFullscreen(document.fullscreenElement === frame)();
  const fractionAt = event => {
    const bounds = slider.getBoundingClientRect();
    return Math.min(1, Math.max(0, (event.clientX - bounds.left) / bounds.width));
  };
  const seekTo = event => {
    const fraction = fractionAt(event);
    point(fraction);
    if (!duration()) return;
    video.currentTime = fraction * duration();
    update();
  };
  const pointerDown = event => {
    slider.setPointerCapture(event.pointerId);
    slider.setAttribute("data-seeking", "");
    seekTo(event);
  };
  const pointerMove = event => {
    if (slider.hasAttribute("data-seeking")) seekTo(event);
    else point(fractionAt(event));
  };
  const pointerUp = event => {
    slider.releasePointerCapture(event.pointerId);
    slider.removeAttribute("data-seeking");
  };
  const lostCapture = () => slider.removeAttribute("data-seeking");
  const keyDown = event => {
    if (event.key === " " || event.key === "k") {
      event.preventDefault();
      onToggle();
      return;
    }
    if (!duration()) return;
    const step = { ArrowRight: seekStep, ArrowUp: seekStep, ArrowLeft: -seekStep, ArrowDown: -seekStep }[event.key];
    if (event.key === "Home") video.currentTime = 0;
    else if (event.key === "End") video.currentTime = duration();
    else if (step) video.currentTime = Math.min(duration(), Math.max(0, video.currentTime + step));
    else return;
    event.preventDefault();
    update();
  };
  const focus = () => update();
  const visibility = new IntersectionObserver(([entry]) => onVisible(entry.isIntersecting)(), { threshold: 0.25 });

  for (const name of ["timeupdate", "loadedmetadata", "durationchange", "emptied"]) video.addEventListener(name, update);
  video.addEventListener("ended", ended);
  document.addEventListener("fullscreenchange", fullscreenChange);
  slider.addEventListener("pointerdown", pointerDown);
  slider.addEventListener("pointermove", pointerMove);
  slider.addEventListener("pointerup", pointerUp);
  slider.addEventListener("pointercancel", pointerUp);
  slider.addEventListener("lostpointercapture", lostCapture);
  slider.addEventListener("keydown", keyDown);
  slider.addEventListener("focus", focus);
  visibility.observe(frame);

  return () => {
    for (const name of ["timeupdate", "loadedmetadata", "durationchange", "emptied"]) video.removeEventListener(name, update);
    video.removeEventListener("ended", ended);
    document.removeEventListener("fullscreenchange", fullscreenChange);
    slider.removeEventListener("pointerdown", pointerDown);
    slider.removeEventListener("pointermove", pointerMove);
    slider.removeEventListener("pointerup", pointerUp);
    slider.removeEventListener("pointercancel", pointerUp);
  slider.removeEventListener("lostpointercapture", lostCapture);
    slider.removeEventListener("keydown", keyDown);
    slider.removeEventListener("focus", focus);
    visibility.disconnect();
  };
};

export const canHover = () => !window.matchMedia("(hover: none)").matches;
