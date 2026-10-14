import { Composition, staticFile } from "remotion";
import { Trailer } from "./Trailer";
import { fps, height, plan, width, type Manifest } from "./timeline";

// render.mjs passes the manifest it writes to public/manifest.json; Remotion Studio fetches it.
export function Root() {
  return (
    <Composition
      id="Trailer"
      component={Trailer}
      fps={fps}
      width={width}
      height={height}
      durationInFrames={1}
      defaultProps={{ manifest: null as unknown as Manifest }}
      calculateMetadata={async ({ props }) => {
        const manifest: Manifest = props.manifest ?? (await fetch(staticFile("manifest.json")).then((response) => response.json()));
        return { durationInFrames: plan(manifest).duration, props: { manifest } };
      }}
    />
  );
}
