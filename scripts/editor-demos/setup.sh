#!/usr/bin/env bash
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel)
TOOLS=${IRIS_DEMO_HOME:-/tmp/iris-editor-tools}
mkdir -p "$TOOLS/profile/User" "$TOOLS/extensions" "$TOOLS/iris-website"

# Native VS Code, rather than a recreation of its UI. See AGENTS.md for apt prerequisites.
if [[ ! -x "$TOOLS/VSCode-linux-x64/code" ]]; then
  curl -fLsS --retry 2 https://update.code.visualstudio.com/1.139.0/linux-x64/stable -o "$TOOLS/code.tar.gz"
  tar xzf "$TOOLS/code.tar.gz" -C "$TOOLS"
fi
if [[ ! -f "$TOOLS/geist.zip" ]]; then
  curl -fLsS --retry 2 https://github.com/vercel/geist-font/releases/download/v1.7.2/geist-font-v1.7.2.zip -o "$TOOLS/geist.zip"
fi
unzip -oq "$TOOLS/geist.zip" 'geist-font/*/ttf/*' -d "$TOOLS"
mkdir -p "$HOME/.local/share/fonts/iris-demos"
cp "$TOOLS"/geist-font/*/ttf/*.ttf "$HOME/.local/share/fonts/iris-demos/"
fc-cache -f "$HOME/.local/share/fonts/iris-demos"

curl -fLsS --retry 2 https://github.com/purefunctor/purescript-iris-vscode/releases/download/v0.1.0/purescript-analyzer-0.1.0.vsix -o "$TOOLS/iris.vsix"
echo "e19528ba5881a509675ce40c427c042f70847c229cac76817f4d542bb41134ab  $TOOLS/iris.vsix" | sha256sum -c -
for extension in nwolverson.language-purescript@0.2.10 Catppuccin.catppuccin-vsc@3.19.0 "$TOOLS/iris.vsix"; do
  "$TOOLS/VSCode-linux-x64/bin/code" --no-sandbox --disable-gpu \
    --user-data-dir "$TOOLS/profile" --extensions-dir "$TOOLS/extensions" \
    --install-extension "$extension" --force
done

# Only disposable recording data is reset. Never edit the seed checkout for a take.
rm -rf "$TOOLS/iris-website/src"
cp -a "$ROOT/src" "$ROOT/spago.yaml" "$ROOT/spago.lock" "$TOOLS/iris-website/"
ln -sfn "$ROOT/.spago" "$TOOLS/iris-website/.spago"
ln -sfn "$ROOT/node_modules" "$TOOLS/iris-website/node_modules"
git -C "$ROOT" rev-parse HEAD > "$TOOLS/seed-commit"

TOOLS="$TOOLS" ROOT="$ROOT" IRIS_BIN=$(command -v iris) node --input-type=module <<'JS'
import { writeFileSync } from 'node:fs';
const { TOOLS: tools, ROOT: root, IRIS_BIN: iris } = process.env;
writeFileSync(`${tools}/profile/User/settings.json`, JSON.stringify({
  'workbench.colorTheme': 'Catppuccin Macchiato',
  'editor.fontFamily': 'Geist Mono',
  'editor.fontSize': 16,
  'editor.lineHeight': 24,
  'editor.fontLigatures': false,
  'editor.semanticHighlighting.enabled': true,
  'editor.minimap.enabled': false,
  'editor.stickyScroll.enabled': false,
  'editor.inlayHints.enabled': 'off',
  'editor.suggest.preview': false,
  'editor.hover.delay': 350,
  'editor.cursorBlinking': 'solid',
  'editor.autoClosingQuotes': 'never',
  'editor.autoClosingBrackets': 'never',
  'editor.autoSurround': 'never',
  'editor.quickSuggestions': false,
  'editor.wordBasedSuggestions': 'off',
  'editor.occurrencesHighlight': 'singleFile',
  'editor.selectionHighlight': false,
  'workbench.editor.enablePreview': false,
  'workbench.startupEditor': 'none',
  'workbench.tips.enabled': false,
  'workbench.secondarySideBar.defaultVisibility': 'hidden',
  'chat.disableAIFeatures': true,
  'chat.commandCenter.enabled': false,
  'window.commandCenter': false,
  'window.title': '${activeEditorShort} — iris-website',
  'window.titleBarStyle': 'custom',
  'window.menuBarVisibility': 'compact',
  'window.zoomLevel': 0,
  'security.workspace.trust.enabled': false,
  'telemetry.telemetryLevel': 'off',
  'update.mode': 'none',
  'extensions.autoUpdate': false,
  'iris.client.serverPath': `${tools}/iris-wrapper.sh`,
  'iris.server.diagnostics.onChange': true,
  'files.exclude': { '**/.spago': true, '**/node_modules': true, '**/output': true },
}, null, 2));
const quote = s => `'${s.replaceAll("'", "'\\''")}'`;
writeFileSync(`${tools}/iris-wrapper.sh`, `#!/bin/sh\nexport IRIS_SPAGO=${quote(root + '/node_modules/.bin/spago')}\nexport PATH=${quote(root + '/node_modules/.bin')}:$PATH\nexec ${quote(iris)} "$@"\n`, { mode: 0o755 });
writeFileSync(`${tools}/fonts.conf`, `<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <include>/etc/fonts/fonts.conf</include>
  <match target="pattern">
    <test name="family" compare="eq"><string>sans-serif</string></test>
    <edit name="family" mode="prepend" binding="strong"><string>Geist</string></edit>
  </match>
  <match target="pattern">
    <test name="family" compare="eq"><string>system-ui</string></test>
    <edit name="family" mode="prepend" binding="strong"><string>Geist</string></edit>
  </match>
</fontconfig>
`);
JS
(cd "$TOOLS/iris-website" && "$TOOLS/iris-wrapper.sh" build)
