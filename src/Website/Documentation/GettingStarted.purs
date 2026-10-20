module Website.Documentation.GettingStarted (component) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import Iris.StyleX as StyleX
import React.Basic (ReactComponent)
import React.Basic.Hooks as Hooks
import Website.Components.CodeBlock as CodeBlock
import Website.Components.Documentation as Documentation
import Website.Components.Installation as Installation
import Website.Components.Logo (logo)
import Website.Components.Terminal as Terminal
import Website.Documentation.Prose (inlineCode, item, link, list, note, paragraph)
import Yoga.React.DOM as DOM

styles = StyleX.create
  { noteRow: { display: "flex", alignItems: "flex-start", gap: 12 }
  -- Center the logo on the first line of the note's text.
  , noteLogo: { width: 20, height: 20, flexShrink: 0, marginBlockStart: 2 }
  }

styleProps = StyleX.recordProps styles

component :: ReactComponent {}
component = unsafePerformEffect $ Hooks.reactComponent "GettingStarted" \_ ->
  pure $ Documentation.documentation
    { page: Documentation.GettingStarted
    , intro:
        [ paragraph
            [ DOM.text "At the end of this page, you will have a project that prints “Hello, Iris!”"
            ]
        , paragraph
            [ DOM.text
                "Please note that this guide is intended for existing users of the PureScript programming language. If you are new to PureScript, it is highly recommended to go through the "
            , link "https://github.com/purescript/documentation" "official documentation"
            , DOM.text " as well as the "
            , link "https://book.purescript.org/" "PureScript book"
            , DOM.text "."
            ]
        ]
    , sections
    }

sections :: Array Documentation.Section
sections =
  [ { id: "try-it-in-your-browser"
    , title: "Try it in your browser"
    , body:
        [ paragraph
            [ DOM.text "The "
            , link "/playground/" "playground"
            , DOM.text
                " is the easiest way to try out Iris. You can write code, create files, and experience the language server without having to install anything on your local machine. Additionally, it also supports both console output and rendering simple single-page applications via "
            , link "https://github.com/purescript-halogen/purescript-halogen" "Halogen"
            , DOM.text " or "
            , link "https://github.com/purescript-react/purescript-react-basic-hooks" "React"
            , DOM.text "."
            ]
        ]
    }
  , { id: "before-you-begin"
    , title: "Before you begin"
    , body:
        [ paragraph [ DOM.text "Install the following tools:" ]
        , list
            [ item
                [ link "https://nodejs.org/en/download" "Node.js"
                , DOM.text " to run JavaScript code. The minimum supported version is 22.5.0."
                ]
            , item
                [ link "https://github.com/purescript/spago" "Spago"
                , DOM.text
                    " is the PureScript package manager, which Iris uses to download packages."
                ]
            ]
        , Terminal.terminal
            [ { command: "node --version", output: "v24.22.0" }
            , { command: "spago --version", output: "1.0.4" }
            ]
        , note
            [ DOM.div styleProps.noteRow
                [ logo { className: styleProps.noteLogo.className }
                , DOM.p {}
                    [ DOM.text "Spago usually requires the PureScript compiler ("
                    , inlineCode "purs"
                    , DOM.text
                        ") to check its installed version. Iris creates a temporary shim for the executable to respond to the request made by Spago."
                    ]
                ]
            ]
        ]
    }
  , { id: "install-iris"
    , title: "Install Iris"
    , body:
        [ paragraph
            [ DOM.text
                "The easiest way to install Iris is via the official installer. The installer downloads the latest stable release from GitHub. Audit the source code yourself, or ask your agent to do so before installation!"
            ]
        , paragraph
            [ DOM.text "If GitHub CLI ("
            , inlineCode "gh"
            , DOM.text
                ") is installed, the installer uses it to verify attestation of the release before installation. Additional documentation for the installer can be found in the "
            , link "/docs/installation/" "installation"
            , DOM.text " page."
            ]
        , Installation.installation { fill: true }
        , paragraph [ DOM.text "Once installed, you can check the current version:" ]
        , Terminal.terminal [ { command: "iris --version", output: "iris 0.1.10" } ]
        , paragraph
            [ DOM.text
                "The installer does not modify system or shell configuration. The installation locations are as follows:"
            ]
        , list
            [ item [ inlineCode "~/.local/bin", DOM.text " for macOS and Linux" ]
            , item [ inlineCode "%LOCALAPPDATA%\\Iris\\bin", DOM.text " for Windows" ]
            ]
        , paragraph
            [ DOM.text "Iris also comes with a tool for self-updates, you can run "
            , inlineCode "iris self update"
            , DOM.text
                " which upgrades the binary in place, downloading the same releases as the installer above."
            ]
        , Terminal.terminal [ { command: "iris self update", output: "" } ]
        ]
    }
  , { id: "create-and-run-a-project"
    , title: "Create and run a project"
    , body:
        [ paragraph
            [ DOM.text
                "You are now ready to create and run a project. First, create a new directory and run "
            , inlineCode "iris new"
            , DOM.text " inside of it. You should see the following output:"
            ]
        , Terminal.terminal
            [ { command: "mkdir hello-iris", output: "" }
            , { command: "cd hello-iris", output: "" }
            , { command: "iris new"
              , output:
                  "Created package `hello-iris` with package set 81.6.0.\nRun `iris build` to get started."
              }
            ]
        , paragraph
            [ DOM.text "Use "
            , inlineCode "iris run"
            , DOM.text
                " to build and run the package. The first build usually downloads packages and writes "
            , inlineCode "spago.lock"
            , DOM.text " first, then it runs "
            , inlineCode "Main.main"
            , DOM.text " with Node.js."
            ]
        , Terminal.terminal
            [ { command: "iris run"
              , output:
                  "Reading Spago workspace configuration...\n\n✓ Selecting package to build: hello-iris\n\nDownloading dependencies...\nNo lockfile found, generating it...\nLockfile written to spago.lock. Please commit this file.\n🍝"
              }
            ]
        , paragraph
            [ DOM.text "Next, change the greeting in "
            , inlineCode "src/Main.purs"
            , DOM.text " to “Hello, Iris!”. You know what to do next."
            ]
        , CodeBlock.codeBlock
            { code:
                "module Main where\n\nimport Prelude\n\nimport Effect (Effect)\nimport Effect.Console (log)\n\nmain :: Effect Unit\nmain = do\n  log \"Hello, Iris!\""
            , filename: "src/Main.purs"
            , highlight: [ 10 ]
            , language: CodeBlock.PureScript
            , lineNumbers: true
            , note: Nothing
            , surface: CodeBlock.Flat
            }
        , Terminal.terminal
            [ { command: "iris run"
              , output:
                  "Reading Spago workspace configuration...\n\n✓ Selecting package to build: hello-iris\n\nDownloading dependencies...\nHello, Iris!"
              }
            ]
        , paragraph
            [ DOM.text
                "Congratulations! You've successfully created and run your first Iris build. Up next, setting up your coding agent or "
            , link "/docs/language-server/" "code editor"
            , DOM.text "."
            ]
        ]
    }
  ]
