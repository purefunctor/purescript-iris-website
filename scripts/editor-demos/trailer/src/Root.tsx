import type { ComponentType } from "react";
import { Composition, staticFile } from "remotion";
import { Trailer } from "./EditorTrailer";
import { plan as editorPlan } from "./editor";
import { PlaygroundTrailer } from "./PlaygroundTrailer";
import { plan as playgroundPlan } from "./playground";
import { fps, height, width } from "./takes";

// One trailer: its component and plan, and the manifest its render script writes to public/ and
// passes as props; Remotion Studio fetches the manifest instead.
function trailer<Manifest>(id: string, component: ComponentType<{ manifest: Manifest }>, plan: (manifest: Manifest) => { duration: number }, manifestFile: string) {
  return (
    <Composition
      key={id}
      id={id}
      component={component}
      fps={fps}
      width={width}
      height={height}
      durationInFrames={1}
      defaultProps={{ manifest: null as unknown as Manifest }}
      calculateMetadata={async ({ props }) => {
        const manifest: Manifest = props.manifest ?? (await fetch(staticFile(manifestFile)).then((response) => response.json()));
        return { durationInFrames: plan(manifest).duration, props: { manifest } };
      }}
    />
  );
}

export function Root() {
  return (
    <>
      {trailer("Trailer", Trailer, editorPlan, "manifest.json")}
      {trailer("Playground", PlaygroundTrailer, playgroundPlan, "playground-manifest.json")}
    </>
  );
}
