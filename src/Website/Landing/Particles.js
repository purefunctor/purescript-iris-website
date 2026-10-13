// Particle bursts for the benchmark's Cold and Hot tabs, drawn on one canvas that only animates
// while particles remain: snowflakes that puff up and drift down for a cold build, and white-hot
// sparks that arc over and cool along the fire ramp for a hot rebuild.

const fireTokens = ["--fire-100", "--fire-200", "--fire-300", "--fire-400", "--fire-500", "--fire-600"];

const random = (from, to) => from + Math.random() * (to - from);

// Resolves a CSS color to RGB channels by painting it, since the canvas can't interpolate `oklch()`.
function channels(color) {
  const probe = document.createElement("canvas").getContext("2d", { willReadFrequently: true });
  probe.canvas.width = probe.canvas.height = 1;
  probe.fillStyle = color;
  probe.fillRect(0, 0, 1, 1);
  return [...probe.getImageData(0, 0, 1, 1).data.slice(0, 3)];
}

// The color of fire at `heat` from 1 (white-hot) to 0 (a dying ember), along the fire ramp.
function fire(ramp, heat) {
  const position = (1 - Math.min(1, Math.max(0, heat))) * (ramp.length - 1);
  const index = Math.min(ramp.length - 2, Math.floor(position));
  const mix = position - index;
  const [r, g, b] = ramp[index].map((channel, i) => Math.round(channel + (ramp[index + 1][i] - channel) * mix));
  return `rgb(${r} ${g} ${b})`;
}

const effects = {
  cold: {
    count: 14,
    blend: "source-over",
    spawn: () => ({ life: random(1.3, 1.9), size: random(2, 3.6), vx: random(-70, 70), vy: random(-110, -70) }),
    update(particle, elapsed) {
      particle.vy += 70 * elapsed;
      particle.vx *= 1 - 1.5 * elapsed;
      particle.x += (particle.vx + Math.sin(particle.age * 4 + particle.phase) * 14) * elapsed;
      particle.y += particle.vy * elapsed;
      particle.rotation += elapsed * 1.5;
    },
    draw(context, particle, colors) {
      const remaining = 1 - particle.age / particle.life;
      context.globalAlpha = Math.min(1, remaining * 2.5);
      context.strokeStyle = particle.tint < 0.6 ? colors.frost300 : colors.frost400;
      context.lineWidth = 1.2;
      context.save();
      context.translate(particle.x, particle.y);
      context.rotate(particle.rotation);
      context.beginPath();
      for (let arm = 0; arm < 3; arm++) {
        const angle = (arm * Math.PI) / 3;
        const dx = Math.cos(angle) * particle.size;
        const dy = Math.sin(angle) * particle.size;
        context.moveTo(-dx, -dy);
        context.lineTo(dx, dy);
      }
      context.stroke();
      context.restore();
    },
  },
  // Sparks add light, so overlapping ones glow brighter. Each is drawn as a streak along its velocity.
  hot: {
    count: 34,
    blend: "lighter",
    spawn: () => ({ life: random(0.45, 0.9), size: random(1, 1.8), vx: random(-170, 170), vy: random(-260, -90) }),
    update(particle, elapsed) {
      particle.vy += 380 * elapsed;
      particle.vx *= 1 - 1.2 * elapsed;
      particle.x += particle.vx * elapsed;
      particle.y += particle.vy * elapsed;
    },
    draw(context, particle, colors) {
      const heat = 1 - particle.age / particle.life;
      context.globalAlpha = Math.min(1, heat * 3);
      context.strokeStyle = fire(colors.fire, heat * 1.1);
      context.lineWidth = particle.size * (0.5 + heat * 0.7);
      context.beginPath();
      context.moveTo(particle.x - particle.vx * 0.03, particle.y - particle.vy * 0.03);
      context.lineTo(particle.x, particle.y);
      context.stroke();
    },
  },
};

export function particleField(canvas) {
  const context = canvas.getContext("2d");
  let particles = [];
  let colors = null;
  let frame = 0;
  let last = 0;

  const step = now => {
    const elapsed = Math.min(0.05, (now - last) / 1000);
    last = now;
    const scale = window.devicePixelRatio || 1;
    context.setTransform(scale, 0, 0, scale, 0, 0);
    context.clearRect(0, 0, canvas.width, canvas.height);
    particles = particles.filter(particle => (particle.age += elapsed) < particle.life);
    context.lineCap = "round";
    for (const particle of particles) {
      particle.effect.update(particle, elapsed);
      context.globalCompositeOperation = particle.effect.blend;
      particle.effect.draw(context, particle, colors);
    }
    context.globalAlpha = 1;
    context.globalCompositeOperation = "source-over";
    frame = particles.length > 0 ? requestAnimationFrame(step) : 0;
  };

  return {
    burst(kind, origin) {
      const bounds = canvas.getBoundingClientRect();
      const scale = window.devicePixelRatio || 1;
      const width = Math.round(bounds.width * scale);
      const height = Math.round(bounds.height * scale);
      if (canvas.width !== width || canvas.height !== height) {
        canvas.width = width;
        canvas.height = height;
      }
      if (!colors) {
        const style = getComputedStyle(canvas);
        const token = name => style.getPropertyValue(name).trim();
        colors = {
          fire: fireTokens.map(name => channels(token(name))),
          frost300: token("--frost-300"),
          frost400: token("--frost-400"),
        };
      }
      const effect = effects[kind];
      const tab = origin.getBoundingClientRect();
      // Particles leave from the tab's upper edge, so they clear its label as they spread.
      for (let index = 0; index < effect.count; index++) {
        const x = tab.left - bounds.left - 8 + Math.random() * (tab.width + 16);
        const y = tab.top - bounds.top + tab.height * Math.random() * 0.3;
        particles.push({
          age: 0,
          effect,
          phase: Math.random() * Math.PI * 2,
          rotation: Math.random() * Math.PI,
          tint: Math.random(),
          x,
          y,
          ...effect.spawn(),
        });
      }
      if (!frame) {
        last = performance.now();
        frame = requestAnimationFrame(step);
      }
    },
    stop() {
      cancelAnimationFrame(frame);
      frame = 0;
      particles = [];
    },
  };
}
