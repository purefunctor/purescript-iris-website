import { atom as createAtom, Provider, useAtom } from "jotai";

export const atom = (initial) => () =>
  typeof initial === "function" ? Object.assign(createAtom(null), { init: initial }) : createAtom(initial);

export const provider = Provider;

const curriedSetters = new WeakMap();

export const useAtomImpl = (tuple) => (atom) => () => {
  const [value, set] = useAtom(atom);
  if (!curriedSetters.has(set)) curriedSetters.set(set, (update) => () => set(update));
  return tuple(value)(curriedSetters.get(set));
};
