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
            "Install Iris on macOS, Linux, or Windows, and choose which release you get, where it goes, and how the installer verifies it."
        , sections
        }

sections :: Array Documentation.Section
sections =
  [ { id: "install-the-latest-release"
    , title: "Install the latest release"
    , body:
        [ paragraph
            [ DOM.text
                "Run the installer for your platform. It downloads the latest stable release from GitHub and installs the "
            , inlineCode "iris"
            , DOM.text " executable."
            ]
        , Installation.installation
        , paragraph
            [ DOM.text
                "The installers support Linux on x86-64, macOS on Intel and Apple silicon, and 64-bit Windows. By default, they install Iris in "
            , inlineCode "~/.local/bin"
            , DOM.text " on macOS and Linux, and in "
            , inlineCode "%LOCALAPPDATA%\\Iris\\bin"
            , DOM.text " on Windows."
            ]
        , paragraph
            [ DOM.text "If that directory isn’t on your "
            , inlineCode "PATH"
            , DOM.text ", the installer says so but doesn’t change it for you. "
            , link "/docs/getting-started#install-iris" "Getting started"
            , DOM.text " shows how to add it."
            ]
        ]
    }
  , { id: "installer-options"
    , title: "Choose a release or directory"
    , body:
        [ paragraph [ DOM.text "The installers read these environment variables:" ]
        , list
            [ item
                [ inlineCode "IRIS_VERSION"
                , DOM.text " — the release tag to install, such as "
                , inlineCode "v0.1.5"
                , DOM.text
                    ". Defaults to the latest stable release. The installers support v0.1.0 and later; for a v0.0.x release, use the installer from that release’s "
                , link "https://github.com/purefunctor/purescript-iris/tags" "Git tag"
                , DOM.text "."
                ]
            , item
                [ inlineCode "IRIS_INSTALL_DIR"
                , DOM.text " — the directory to install Iris in, instead of the default."
                ]
            , item
                [ inlineCode "IRIS_SKIP_ATTESTATION"
                , DOM.text " — set to "
                , inlineCode "1"
                , DOM.text " to skip release verification. See "
                , link "#verify-releases" "Verify releases"
                , DOM.text "."
                ]
            ]
        , paragraph
            [ DOM.text "On macOS and Linux, set them for the shell that runs the installer:" ]
        , Terminal.terminal
            [ { command: "curl -fsSL https://iris-lang.com/install.sh | IRIS_VERSION=v0.1.5 sh"
              , output: ""
              }
            ]
        , paragraph
            [ DOM.text "In PowerShell, set them before running the installer, for example "
            , inlineCode "$env:IRIS_VERSION = \"v0.1.5\""
            , DOM.text "."
            ]
        ]
    }
  , { id: "verify-releases"
    , title: "Verify releases"
    , body:
        [ paragraph
            [ DOM.text "When the "
            , link "https://cli.github.com/" "GitHub CLI"
            , DOM.text " ("
            , inlineCode "gh"
            , DOM.text
                ") with attestation support is installed, the installers verify the downloaded release’s GitHub build-provenance attestation and stop if verification fails. Without it, they display a warning and continue without verification."
            ]
        , paragraph
            [ DOM.text "Set "
            , inlineCode "IRIS_SKIP_ATTESTATION=1"
            , DOM.text " to skip verification explicitly, for example when "
            , inlineCode "gh"
            , DOM.text
                " is installed but can’t access attestations. This reduces provenance assurance, and the installer prints a warning. In PowerShell, set "
            , inlineCode "$env:IRIS_SKIP_ATTESTATION = \"1\""
            , DOM.text " before running the installer."
            ]
        ]
    }
  , { id: "canary-builds"
    , title: "Canary builds"
    , body:
        [ paragraph
            [ DOM.text "Successful builds of the "
            , inlineCode "main"
            , DOM.text " branch are published as GitHub prereleases tagged "
            , inlineCode "v<version>-dev.<revision>"
            , DOM.text
                ". To test against the canary channel, find the newest published, non-draft prerelease on the "
            , link "https://github.com/purefunctor/purescript-iris/releases" "releases page"
            , DOM.text " and pass its exact tag through "
            , inlineCode "IRIS_VERSION"
            , DOM.text ". Installations without "
            , inlineCode "IRIS_VERSION"
            , DOM.text " continue to use GitHub’s latest stable release."
            ]
        ]
    }
  , { id: "packaging"
    , title: "Packaging Iris"
    , body:
        [ paragraph
            [ DOM.text
                "Iris keeps its package version separate from source provenance. When building Iris with Cargo, packagers can set "
            , inlineCode "IRIS_BUILD_REVISION"
            , DOM.text
                " to a Git revision to include it in the versions that the CLI and language server report."
            ]
        , paragraph
            [ DOM.text
                "The value is read at compile time and must contain 7 to 64 hexadecimal characters. A 0.1.5 build with the revision "
            , inlineCode "bcea1aafe65e"
            , DOM.text " reports:"
            ]
        , Terminal.terminal [ { command: "iris --version", output: "iris 0.1.5-dev.bcea1aafe65e" } ]
        , paragraph
            [ DOM.text "Builds that omit the variable report the package version unchanged." ]
        ]
    }
  ]
