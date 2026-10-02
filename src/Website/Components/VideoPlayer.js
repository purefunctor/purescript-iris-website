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
// The progress fill is written directly to avoid re-rendering on every frame of seeking.
export const observePlayer = ({
  frame: frameRef,
  onEnded,
  onFullscreen,
  onTime,
  onToggle,
  onVisible,
  progress: progressRef,
  slider: sliderRef,
  video: videoRef,
}) => () => {
  const frame = frameRef.current;
  const progress = progressRef.current;
  const slider = sliderRef.current;
  const video = videoRef.current;
  if (!frame || !progress || !slider || !video) return () => {};

  const update = () => {
    const duration = Number.isFinite(video.duration) ? video.duration : 0;
    progress.style.transform = `scaleX(${duration ? video.currentTime / duration : 0})`;
    onTime(video.currentTime)(duration)();
  };
  const ended = () => onEnded();
  const fullscreenChange = () => onFullscreen(document.fullscreenElement === frame)();
  const seekTo = event => {
    if (!video.duration) return;
    const bounds = slider.getBoundingClientRect();
    const fraction = Math.min(1, Math.max(0, (event.clientX - bounds.left) / bounds.width));
    video.currentTime = fraction * video.duration;
    update();
  };
  const pointerDown = event => {
    slider.setPointerCapture(event.pointerId);
    seekTo(event);
  };
  const pointerMove = event => {
    if (event.buttons & 1) seekTo(event);
  };
  const pointerUp = event => slider.releasePointerCapture(event.pointerId);
  const keyDown = event => {
    if (event.key === " " || event.key === "k") {
      event.preventDefault();
      onToggle();
      return;
    }
    if (!video.duration) return;
    const step = { ArrowRight: seekStep, ArrowUp: seekStep, ArrowLeft: -seekStep, ArrowDown: -seekStep }[event.key];
    if (event.key === "Home") video.currentTime = 0;
    else if (event.key === "End") video.currentTime = video.duration;
    else if (step) video.currentTime = Math.min(video.duration, Math.max(0, video.currentTime + step));
    else return;
    event.preventDefault();
    update();
  };
  const visibility = new IntersectionObserver(([entry]) => onVisible(entry.isIntersecting)(), { threshold: 0.25 });

  for (const name of ["timeupdate", "loadedmetadata", "durationchange", "emptied"]) video.addEventListener(name, update);
  video.addEventListener("ended", ended);
  document.addEventListener("fullscreenchange", fullscreenChange);
  slider.addEventListener("pointerdown", pointerDown);
  slider.addEventListener("pointermove", pointerMove);
  slider.addEventListener("pointerup", pointerUp);
  slider.addEventListener("keydown", keyDown);
  visibility.observe(frame);

  return () => {
    for (const name of ["timeupdate", "loadedmetadata", "durationchange", "emptied"]) video.removeEventListener(name, update);
    video.removeEventListener("ended", ended);
    document.removeEventListener("fullscreenchange", fullscreenChange);
    slider.removeEventListener("pointerdown", pointerDown);
    slider.removeEventListener("pointermove", pointerMove);
    slider.removeEventListener("pointerup", pointerUp);
    slider.removeEventListener("keydown", keyDown);
    visibility.disconnect();
  };
};

export const canHover = () => !window.matchMedia("(hover: none)").matches;
