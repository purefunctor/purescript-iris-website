module Website.Documentation.Installation (component) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Hooks as Hooks
import Website.Components.CodeBlock as CodeBlock
import Website.Components.Documentation as Documentation
import Website.Components.Installation as Installation
import Website.Components.Terminal as Terminal
import Website.Documentation.Prose (inlineCode, item, link, list, paragraph)
import Yoga.React.DOM as DOM

component :: ReactComponent {}
component = unsafePerformEffect $ Hooks.reactComponent "Installation" \_ ->
  pure $ Documentation.documentation
    { page: Documentation.Installation
    , intro:
        [ paragraph
            [ DOM.text
                "The official installer is the easiest way to install Iris on macOS, Linux, and Windows. This page covers how to choose a version or installation directory, verify releases, and keep Iris up to date."
            ]
        ]
    , sections
    }

sections :: Array Documentation.Section
sections =
  [ { id: "install-the-latest-release"
    , title: "Install the latest release"
    , body:
        [ paragraph
            [ DOM.text
                "Iris is available for Linux on x86-64 and ARM64, macOS on Intel and Apple silicon, and 64-bit Windows. To install the latest stable release, run the command for your platform:"
            ]
        , Installation.installation { fill: true }
        , paragraph
            [ DOM.text "The installer downloads Iris from GitHub and places the "
            , inlineCode "iris"
            , DOM.text " executable in "
            , inlineCode "~/.local/bin"
            , DOM.text " on macOS and Linux, or in "
            , inlineCode "%LOCALAPPDATA%\\Iris\\bin"
            , DOM.text " on Windows. The installer does not modify your PATH."
            ]
        ]
    }
  , { id: "installer-options"
    , title: "Choose a release or directory"
    , body:
        [ paragraph
            [ DOM.text "You can configure the installer with the following environment variables:" ]
        , list
            [ item
                [ inlineCode "IRIS_VERSION"
                , DOM.text
                    " selects a release by its tag. The installer selects the latest stable release otherwise."
                ]
            , item [ inlineCode "IRIS_INSTALL_DIR", DOM.text " sets the installation directory." ]
            , item
                [ inlineCode "IRIS_SKIP_ATTESTATION"
                , DOM.text " disables release verification when set to "
                , inlineCode "1"
                , DOM.text ". See "
                , link "#verify-releases" "Verify releases"
                , DOM.text "."
                ]
            ]
        , paragraph [ DOM.text "On macOS and Linux:" ]
        , CodeBlock.codeBlock
            { code:
                "export IRIS_VERSION=v0.1.5\ncurl -fsSL https://iris-lang.com/install.sh | sh\n# optional: unset IRIS_VERSION"
            , filename: "Shell"
            , highlight: []
            , language: CodeBlock.Shell
            , lineNumbers: false
            , note: Nothing
            , surface: CodeBlock.Flat
            }
        , paragraph [ DOM.text "On Windows PowerShell:" ]
        , CodeBlock.codeBlock
            { code: "$env:IRIS_VERSION = \"v0.1.5\"\nirm https://iris-lang.com/install.ps1 | iex"
            , filename: "PowerShell"
            , highlight: []
            , language: CodeBlock.Shell
            , lineNumbers: false
            , note: Nothing
            , surface: CodeBlock.Flat
            }
        ]
    }
  , { id: "verify-releases"
    , title: "Verify releases"
    , body:
        [ paragraph
            [ DOM.text
                "Iris releases are built with GitHub Actions. GitHub signs a record of the repository and workflow that built each release archive; this is called a build provenance attestation. The installer verifies this record before installation to confirm that the download came from the Iris repository and was not modified."
            ]
        , paragraph
            [ DOM.text "Verification requires the "
            , link "https://cli.github.com/" "GitHub CLI"
            , DOM.text " ("
            , inlineCode "gh"
            , DOM.text ") with the "
            , inlineCode "gh attestation"
            , DOM.text ". Without "
            , inlineCode "gh"
            , DOM.text
                ", the installer warns you and continues without verification. If verification fails, the installer stops. If "
            , inlineCode "gh"
            , DOM.text " cannot access the attestations, use "
            , inlineCode "IRIS_SKIP_ATTESTATION=1"
            , DOM.text " or "
            , inlineCode "$env:IRIS_SKIP_ATTESTATION = \"1\""
            , DOM.text " in PowerShell to skip verification."
            ]
        ]
    }
  , { id: "install-with-nix"
    , title: "Install with Nix"
    , body:
        [ paragraph
            [ DOM.text "Nix users can use the community-maintained "
            , link "https://github.com/sectore/purescript-iris-nix" "purescript-iris-nix"
            , DOM.text
                " flake instead of the install scripts. It builds Iris from source and provides the "
            , inlineCode "iris"
            , DOM.text " command. Its "
            , link "https://github.com/sectore/purescript-iris-nix#readme" "README"
            , DOM.text " describes how to use it. Update Iris through the flake rather than with "
            , inlineCode "iris self update"
            , DOM.text "."
            ]
        ]
    }
  , { id: "update-iris"
    , title: "Update Iris"
    , body:
        [ paragraph
            [ DOM.text
                "If you installed Iris with a tool such as Cargo, mise, or Nix, use that tool to update it. Otherwise, run:"
            ]
        , Terminal.terminal [ { command: "iris self update", output: "" } ]
        , paragraph
            [ DOM.text "The command replaces the running "
            , inlineCode "iris"
            , DOM.text
                " executable with the latest release on its channel. If you have a stable release, this gives you the latest stable release. A "
            , link "#canary-builds" "canary build"
            , DOM.text ", whose version ends in "
            , inlineCode "-dev.<revision>"
            , DOM.text ", updates to the latest canary build."
            ]
        , paragraph
            [ DOM.text "To see the available options, including how to choose a release, run:" ]
        , Terminal.terminal [ { command: "iris self update --help", output: "" } ]
        ]
    }
  , { id: "canary-builds"
    , title: "Canary builds"
    , body:
        [ paragraph
            [ DOM.text
                "You can use canary builds to try changes before they are released. Every successful build of the "
            , inlineCode "main"
            , DOM.text " branch is published on GitHub as a prerelease, tagged "
            , inlineCode "v<version>-dev.<revision>"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text "To install a canary build, find the newest prerelease on the "
            , link "https://github.com/purefunctor/purescript-iris/releases" "releases page"
            , DOM.text " and pass its tag in "
            , inlineCode "IRIS_VERSION"
            , DOM.text ". The install scripts do not select canary builds automatically. Without "
            , inlineCode "IRIS_VERSION"
            , DOM.text ", they install the latest stable release."
            ]
        , paragraph
            [ inlineCode "iris self update --canary"
            , DOM.text " switches to the latest canary build, and "
            , inlineCode "iris self update --stable"
            , DOM.text " switches back to stable releases. See "
            , link "#update-iris" "Update Iris"
            , DOM.text "."
            ]
        ]
    }
  , { id: "packaging"
    , title: "Packaging Iris"
    , body:
        [ paragraph
            [ DOM.text "When building Iris with Cargo, set "
            , inlineCode "IRIS_BUILD_REVISION"
            , DOM.text
                " to include a Git revision in the version reported by the CLI and language server. The revision must be 7 to 64 hexadecimal characters."
            ]
        , paragraph
            [ DOM.text "For example, a 0.1.13 build with the revision "
            , inlineCode "7ddab4481c3b"
            , DOM.text " reports:"
            ]
        , Terminal.terminal
            [ { command: "iris --version", output: "iris 0.1.13-dev.7ddab4481c3b" } ]
        , paragraph
            [ DOM.text "Builds without the variable report only the package version, such as "
            , inlineCode "iris 0.1.13"
            , DOM.text "."
            ]
        ]
    }
  ]
