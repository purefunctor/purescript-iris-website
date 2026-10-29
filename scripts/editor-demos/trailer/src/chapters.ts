export type Feature = { slug: string; title: string };
export type Act = { heading: string; emphasis: string; features: Feature[] };

export const acts: Act[] = [
  {
    heading: "Reading",
    emphasis: "code.",
    features: [
      {
        slug: "semantic-highlighting",
        title: "Semantic highlighting",
      },
      {
        slug: "go-to-definition",
        title: "Go to definition",
      },
      {
        slug: "information-on-hover",
        title: "Hover",
      },
      {
        slug: "document-highlights",
        title: "Document highlights",
      },
      {
        slug: "document-symbols",
        title: "Document symbols",
      },
      {
        slug: "find-references",
        title: "Find references",
      },
      {
        slug: "workspace-symbols",
        title: "Workspace symbols",
      },
    ],
  },
  {
    heading: "Writing",
    emphasis: "code.",
    features: [
      {
        slug: "rename",
        title: "Rename",
      },
      {
        slug: "automatic-import",
        title: "Automatic imports",
      },
      {
        slug: "completion",
        title: "Completion",
      },
      {
        slug: "typed-hole-suggestions",
        title: "Typed holes",
      },
      {
        slug: "live-diagnostics",
        title: "Diagnostics",
      },
    ],
  },
];

export const features = acts.flatMap((act) => act.features);
