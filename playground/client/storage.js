// Keeps the project in local storage and encodes it into share links.

const KEY = "iris-playground-project";
const VERSION = 1;

export function loadSavedProject() {
  try {
    return validate(JSON.parse(localStorage.getItem(KEY)));
  } catch {
    return null;
  }
}

export function saveProject(project) {
  try {
    localStorage.setItem(KEY, JSON.stringify({ version: VERSION, ...project }));
  } catch {
    // Storage can be full or disabled; the project still lives in the page.
  }
}

/** A `#project=` fragment holding the project, compressed and base64url-encoded. */
export async function encodeProject(project) {
  const json = JSON.stringify({ version: VERSION, files: project.files, open: project.open, active: project.active });
  const stream = new Blob([json]).stream().pipeThrough(new CompressionStream("deflate-raw"));
  const bytes = new Uint8Array(await new Response(stream).arrayBuffer());
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return `#project=${btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "")}`;
}

export async function decodeProject(hash) {
  const encoded = /^#project=([\w-]+)$/.exec(hash)?.[1];
  if (!encoded) return null;
  const binary = atob(encoded.replaceAll("-", "+").replaceAll("_", "/"));
  const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
  const stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream("deflate-raw"));
  return validate(JSON.parse(await new Response(stream).text()));
}

function validate(project) {
  if (project?.version !== VERSION || !Array.isArray(project.files) || project.files.length === 0) return null;
  const files = project.files.filter(
    (file) => typeof file?.path === "string" && typeof file.text === "string" && /^src\/.+\.(purs|js)$/.test(file.path),
  );
  if (files.length === 0) return null;
  const open = Array.isArray(project.open) ? project.open.filter((path) => typeof path === "string") : undefined;
  return { files, open, active: typeof project.active === "string" ? project.active : undefined };
}
