module Website.Documentation.Installation (component) where

import Prelude

import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Hooks as Hooks
import Website.Components.Documentation as Documentation
import Website.Components.Installation as Installation
import Website.Components.Terminal as Terminal
import Website.Documentation.Prose (inlineCode, item, link, list, paragraph)
import Yoga.React.DOM as DOM

component :: ReactComponent {}
component = unsafePerformEffect $ Hooks.reactComponent "Installation" \_ -> Hooks.do
  Hooks.useEffectOnce Documentation.configurePlatform
  pure
    $ Documentation.documentation
        { page: Documentation.Installation
        , intro:
            "Iris provides install scripts for macOS, Linux, and Windows. By default, the scripts install the latest stable release. They can also install a specific version, use a different installation directory, or install a canary build."
        , sections
        }

sections :: Array Documentation.Section
sections =
  [ { id: "install-the-latest-release"
    , title: "Install the latest release"
    , body:
        [ paragraph
            [ DOM.text
                "Releases are available for Linux on x86-64, macOS on Intel and Apple silicon, and 64-bit Windows. To install the latest stable release, run the command for your platform:"
            ]
        , Installation.installation { fill: true }
        , paragraph
            [ DOM.text "The script downloads Iris from GitHub and installs the "
            , inlineCode "iris"
            , DOM.text " executable in "
            , inlineCode "~/.local/bin"
            , DOM.text " on macOS and Linux, or in "
            , inlineCode "%LOCALAPPDATA%\\Iris\\bin"
            , DOM.text " on Windows."
            ]
        , paragraph
            [ DOM.text
                "The script does not modify your PATH. If the installation directory is not on your PATH, the script prints a reminder. "
            , link "/docs/getting-started#install-iris" "Getting started"
            , DOM.text " explains how to add it."
            ]
        ]
    }
  , { id: "installer-options"
    , title: "Choose a release or directory"
    , body:
        [ paragraph [ DOM.text "The install scripts read the following environment variables:" ]
        , list
            [ item
                [ inlineCode "IRIS_VERSION"
                , DOM.text " selects a release by its tag, such as "
                , inlineCode "v0.1.5"
                , DOM.text ". If it is not set, the latest stable release is installed."
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
        , paragraph
            [ DOM.text "On macOS and Linux, set the variables immediately before "
            , inlineCode "sh"
            , DOM.text " so that they apply to the script:"
            ]
        , Terminal.terminal
            [ { command: "curl -fsSL https://iris-lang.com/install.sh | IRIS_VERSION=v0.1.5 sh"
              , output: ""
              }
            ]
        , paragraph
            [ DOM.text
                "In PowerShell, set the variables before running the install command. For example, "
            , inlineCode "$env:IRIS_VERSION = \"v0.1.5\""
            , DOM.text " selects version 0.1.5."
            ]
        , paragraph
            [ DOM.text
                "The install scripts support Iris 0.1.0 and later. To install a 0.0.x release, use the install script from that release's "
            , link "https://github.com/purefunctor/purescript-iris/tags" "Git tag"
            , DOM.text "."
            ]
        ]
    }
  , { id: "verify-releases"
    , title: "Verify releases"
    , body:
        [ paragraph
            [ DOM.text
                "Iris releases are built with GitHub Actions. For each release archive, GitHub signs a record of the repository and workflow that built it, known as a build provenance attestation. The install scripts verify this record before installing, which confirms that the download came from the Iris repository and was not modified."
            ]
        , paragraph
            [ DOM.text "Verification requires the "
            , link "https://cli.github.com/" "GitHub CLI"
            , DOM.text " ("
            , inlineCode "gh"
            , DOM.text ") with the "
            , inlineCode "gh attestation"
            , DOM.text " command. If "
            , inlineCode "gh"
            , DOM.text
                " is installed and verification fails, the script stops without installing anything. If "
            , inlineCode "gh"
            , DOM.text
                " is not installed, the script prints a warning and installs Iris without verification."
            ]
        , paragraph
            [ DOM.text "If "
            , inlineCode "gh"
            , DOM.text " is installed but cannot access the attestations, set "
            , inlineCode "IRIS_SKIP_ATTESTATION=1"
            , DOM.text ", or "
            , inlineCode "$env:IRIS_SKIP_ATTESTATION = \"1\""
            , DOM.text
                " in PowerShell, to skip verification. The script then prints a warning, because it cannot confirm where the download came from."
            ]
        ]
    }
  , { id: "canary-builds"
    , title: "Canary builds"
    , body:
        [ paragraph
            [ DOM.text
                "Canary builds allow you to test changes before they are released. Every successful build of the "
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
        ]
    }
  , { id: "packaging"
    , title: "Packaging Iris"
    , body:
        [ paragraph
            [ DOM.text
                "When building Iris from source with Cargo, for example to package it for a Linux distribution, you can include the Git revision in the version reported by the CLI and the language server. Set "
            , inlineCode "IRIS_BUILD_REVISION"
            , DOM.text
                " to the revision when building. The value is read at compile time and must be 7 to 64 hexadecimal characters long."
            ]
        , paragraph
            [ DOM.text "For example, a 0.1.5 build with the revision "
            , inlineCode "bcea1aafe65e"
            , DOM.text " reports:"
            ]
        , Terminal.terminal [ { command: "iris --version", output: "iris 0.1.5-dev.bcea1aafe65e" } ]
        , paragraph
            [ DOM.text "Builds without the variable report only the package version, such as "
            , inlineCode "iris 0.1.5"
            , DOM.text "."
            ]
        ]
    }
  ]
