module Website.Documentation.Installation (component) where

import Prelude

import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Hooks as Hooks
import Website.Components.Documentation as Documentation
import Website.Components.Installation as Installation
import Website.Components.Terminal as Terminal
import Website.Documentation.Prose (inlineCode, item, link, list, note, paragraph)
import Yoga.React.DOM as DOM

component :: ReactComponent {}
component = unsafePerformEffect $ Hooks.reactComponent "Installation" \_ -> Hooks.do
  Hooks.useEffectOnce Documentation.configurePlatform
  pure
    $ Documentation.documentation
        { page: Documentation.Installation
        , intro:
            "Iris provides install scripts for macOS, Linux, and Windows. By default, the scripts install the latest stable release. They can also install a specific version, use a different installation directory, or install a canary build. Releases after 0.1.6 can also update themselves."
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
  , { id: "update-iris"
    , title: "Update Iris"
    , body:
        [ note
            [ DOM.strong {} "Requires a release after v0.1.6"
            , DOM.p
                {}
                [ DOM.text "Iris 0.1.6 and earlier do not include "
                , inlineCode "iris self update"
                , DOM.text
                    ". To update from one of these releases, run the install script again. Later updates can use the command below."
                ]
            ]
        , paragraph [ DOM.text "To update Iris to the latest release, run:" ]
        , Terminal.terminal [ { command: "iris self update", output: "" } ]
        , paragraph
            [ DOM.text "The command replaces the running "
            , inlineCode "iris"
            , DOM.text
                " executable with the latest release on its channel. A stable release updates to the latest stable release. A "
            , link "#canary-builds" "canary build"
            , DOM.text ", whose version ends in "
            , inlineCode "-dev.<revision>"
            , DOM.text ", updates to the latest canary build."
            ]
        , paragraph [ DOM.text "The command also accepts a release tag and the following options:" ]
        , list
            [ item
                [ inlineCode "iris self update v0.1.6"
                , DOM.text
                    " installs a specific release by its tag, including an older release. As with the install scripts, Iris 0.1.0 and later are supported."
                ]
            , item
                [ inlineCode "--stable"
                , DOM.text " and "
                , inlineCode "--canary"
                , DOM.text " switch to the latest release on the stable or canary channel."
                ]
            , item
                [ inlineCode "--check"
                , DOM.text
                    " reports whether a different release is available, without installing it. The command exits with status 0 if Iris is up to date, 100 if a different release is available, and 1 if an error occurs."
                ]
            ]
        , paragraph
            [ DOM.text
                "Iris 0.1.6 and earlier cannot update themselves. If you install one of these releases with "
            , inlineCode "iris self update"
            , DOM.text ", Iris prints a warning, and later updates must use the install script."
            ]
        , paragraph
            [ DOM.text "Running "
            , inlineCode "iris watch"
            , DOM.text " processes and editor "
            , link "/docs/language-server" "language servers"
            , DOM.text
                " continue to use the previous version until they are restarted. Restart them after updating."
            ]
        ]
    }
  , { id: "how-updates-work"
    , title: "How updates are installed"
    , body:
        [ paragraph
            [ inlineCode "iris self update"
            , DOM.text
                " replaces the executable that is running, regardless of how it was installed. If the "
            , inlineCode "iris"
            , DOM.text
                " command on your PATH is a symbolic link, the link continues to point to the updated file."
            ]
        , paragraph
            [ DOM.text
                "If you installed Iris with another tool, such as Cargo, mise, or Nix, update it with that tool instead. "
            , inlineCode "iris self update"
            , DOM.text
                " also replaces copies installed by other tools, but the tool's records then remain out of date until it reinstalls Iris."
            ]
        , paragraph
            [ DOM.text
                "If Iris cannot write to its installation directory, for example because it was installed in "
            , inlineCode "/usr/local/bin"
            , DOM.text " with "
            , inlineCode "sudo"
            , DOM.text
                ", the command stops before downloading anything. Run the update with the same permissions that were used to install Iris."
            ]
        , paragraph
            [ DOM.text "Updates are verified in the same way as installations, as described in "
            , link "#verify-releases" "Verify releases"
            , DOM.text ". "
            , inlineCode "IRIS_SKIP_ATTESTATION=1"
            , DOM.text " also skips verification for updates. If "
            , inlineCode "gh"
            , DOM.text " is installed but not signed in, the update stops and asks you to run "
            , inlineCode "gh auth login"
            , DOM.text " or set "
            , inlineCode "IRIS_SKIP_ATTESTATION=1"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text
                "Downloads use HTTPS and the operating system's certificate store, so proxies that use a private certificate authority are supported. Iris respects "
            , inlineCode "HTTPS_PROXY"
            , DOM.text
                " and the related proxy variables. On the canary channel, Iris uses the GitHub API to find the latest canary build. To avoid API rate limits, set "
            , inlineCode "GH_TOKEN"
            , DOM.text " or "
            , inlineCode "GITHUB_TOKEN"
            , DOM.text ". Iris sends the token only with these API requests."
            ]
        , paragraph
            [ DOM.text
                "On Windows, a running executable cannot be deleted, so the previous executable is kept next to the new one as "
            , inlineCode "iris.exe.old"
            , DOM.text
                ". The next update removes it. If that file is still in use, the update stops and asks you to stop the Iris processes that use it before trying again."
            ]
        , paragraph
            [ DOM.text
                "Updates are available on the same platforms as the install scripts. On other platforms, the command reports that no release is built for the platform and advises updating Iris with the tool that built it."
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
        , paragraph
            [ DOM.text "In releases after 0.1.6, "
            , inlineCode "iris self update --canary"
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
