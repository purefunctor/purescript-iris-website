const ring = ["red", "orange", "yellow", "green", "blue", "indigo"];

export const marks = [
  { x: 16, y: 16, radius: 3.5, color: "violet" },
  ...ring.map((color, index) => {
    const angle = ((index * 60 - 110) * Math.PI) / 180;
    return { x: 16 + 8.5 * Math.cos(angle), y: 16 + 8.5 * Math.sin(angle), radius: 3.5, color };
  }),
];
