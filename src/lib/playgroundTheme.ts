import { readColorTokens } from "#src/lib/colorTokens.ts";
import { themeSettings } from "../../scripts/editor-demos/theme.ts";

type Rule = { token: string; foreground?: string; fontStyle?: string };

export async function playgroundTheme() {
  const settings = await themeSettings();
  const tokens = await readColorTokens();
  const hex = (value: string) => value.replace(/^#/, "");
  const syntax = (name: string) => {
    const value = tokens[`syn-${name}`];
    if (!value) throw new Error(`global.css has no opaque --syn-${name} token`);
    return hex(value);
  };

  const grammar: Rule[] = [
    { token: "", foreground: syntax("text") },
    { token: "identifier", foreground: syntax("text") },
    { token: "comment", foreground: syntax("comment"), fontStyle: "italic" },
    { token: "keyword", foreground: syntax("keyword") },
    { token: "type", foreground: syntax("type") },
    { token: "string", foreground: syntax("string") },
    { token: "number", foreground: syntax("number") },
    { token: "operator", foreground: syntax("operator") },
    { token: "delimiter", foreground: syntax("punct") },
  ];

  const semantic = settings["editor.semanticTokenColorCustomizations"] as {
    rules: Record<string, string | { foreground: string; italic?: boolean }>;
  };
  const semanticRules = Object.entries(semantic.rules).map(([token, style]): Rule =>
    typeof style === "string"
      ? { token, foreground: hex(style) }
      : { token, foreground: hex(style.foreground), fontStyle: style.italic ? "italic" : "" },
  );

  return {
    base: "vs-dark",
    inherit: true,
    rules: [...grammar, ...semanticRules],
    colors: settings["workbench.colorCustomizations"] as Record<string, string>,
  };
}
