module Website.Documentation.GettingStarted (component) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent)
import React.Basic.Hooks as Hooks
import Website.Components.CodeBlock as CodeBlock
import Website.Components.Documentation as Documentation
import Website.Components.Installation as Installation
import Website.Components.Terminal as Terminal
import Yoga.React.DOM as DOM

foreign import configurePlatform :: Effect (Effect Unit)

styles =
  StyleX.create
    { page: { fontSize: 16, lineHeight: 1.75, color: "var(--text-secondary)" }
    , paragraph: { maxWidth: "72ch" }
    , inlineCode:
        { fontFamily: "var(--font-mono)"
        , fontSize: "0.86em"
        , color: "var(--text-primary)"
        , backgroundColor: "var(--surface-1)"
        , paddingInline: 5
        , paddingBlock: 2
        }
    , list: { paddingInlineStart: 22, display: "flex", flexDirection: "column", gap: 10 }
    , link:
        { color: { default: "var(--accent-text)", ":hover": "var(--iris-200)" }
        , textUnderlineOffset: 4
        , outlineColor: "var(--focus-ring)"
        }
    , note:
        { backgroundColor: "var(--surface-1)"
        , display: "flex"
        , flexDirection: "column"
        , gap: 12
        , padding: 20
        , fontSize: 14
        , lineHeight: 1.7
        , color: "var(--text-secondary)"
        }
    }

styleProps = StyleX.recordProps styles

component :: ReactComponent {}
component = unsafePerformEffect $ Hooks.reactComponent "GettingStarted" \_ -> Hooks.do
  Hooks.useEffectOnce configurePlatform
  pure
    $ DOM.div
        styleProps.page
        [ Documentation.documentation
            { title: "Getting started"
            , intro:
                "Install Iris, create your first workspace, and run a small command-line application with Node.js."
            , sections
            }
        ]

sections :: Array Documentation.Section
sections =
  [ { id: "before-you-begin"
    , title: "Before you begin"
    , body:
        [ paragraph
            [ DOM.text "You’ll need "
            , link "https://nodejs.org/en/download" "Node.js"
            , DOM.text " 22.5.0 or later (with npm), "
            , link "https://git-scm.com/downloads" "Git"
            , DOM.text ", and an internet connection for your first workspace and build."
            ]
        , paragraph
            [ DOM.text "Iris uses "
            , link "https://github.com/purescript/spago" "Spago"
            , DOM.text
                " to resolve and download PureScript packages. Install it and check that your tools are available:"
            ]
        , Terminal.terminal
            [ { command: "npm install --global spago@1.0.4", output: "" }
            , { command: "node --version", output: "v22.23.3" }
            , { command: "git --version", output: "git version 2.55.0" }
            , { command: "spago --version", output: "1.0.4" }
            ]
        , paragraph
            [ DOM.text
                "The outputs in this guide are examples. Versions and Registry package sets may differ on your machine."
            ]
        , paragraph
            [ DOM.text "You don’t need to install the official "
            , inlineCode "purs"
            , DOM.text
                " compiler. Iris compiles your code and supplies the compatibility shim Spago needs."
            ]
        ]
    }
  , { id: "install-iris"
    , title: "Install Iris"
    , body:
        [ paragraph
            [ DOM.text
                "Run the installer for your platform. It downloads the latest stable Iris release."
            ]
        , Installation.installation
        , paragraph
            [ DOM.text
                "Use “Show source” to inspect the script before running it. Then make sure the installation directory is on your "
            , inlineCode "PATH"
            , DOM.text " and check the compiler:"
            ]
        , Terminal.terminal [ { command: "iris --version", output: "iris 0.1.5" } ]
        , DOM.aside
            styleProps.note
            [ DOM.strong {} "If your shell can’t find Iris"
            , DOM.p
                {}
                [ DOM.text "On macOS and Linux, the default directory is "
                , inlineCode "~/.local/bin"
                , DOM.text ". Add it to your PATH for this session:"
                ]
            , Terminal.terminal
                [ { command: "export PATH=\"$HOME/.local/bin:$PATH\"", output: "" } ]
            , DOM.p {} "Add the same command to your shell configuration for future terminals."
            , DOM.p
                {}
                [ DOM.text "On Windows, add "
                , inlineCode "%LOCALAPPDATA%\\Iris\\bin"
                , DOM.text
                    " to your user Path and reopen PowerShell. The installers print PATH advice but don’t change it for you."
                ]
            ]
        , paragraph
            [ DOM.text "A GitHub CLI ("
            , inlineCode "gh"
            , DOM.text
                ") with attestation support lets the installer verify release provenance. Without it, the installer warns and continues without verification."
            ]
        ]
    }
  , { id: "create-a-workspace"
    , title: "Create a workspace"
    , body:
        [ paragraph
            [ DOM.text
                "Create an empty directory outside any existing Spago workspace, then initialize it. "
            , inlineCode "iris new"
            , DOM.text " works in the current directory and uses its name for your package."
            ]
        , Terminal.terminal
            [ { command: "mkdir hello-iris", output: "" }
            , { command: "cd hello-iris", output: "" }
            , { command: "iris new"
              , output:
                  "Created package `hello-iris` with package set 81.3.0.\nRun `iris build` to get started."
              }
            ]
        , paragraph
            [ DOM.text
                "Iris asks Spago for a compatible Registry package set and creates these files:"
            ]
        , DOM.ul
            styleProps.list
            [ item
                [ inlineCode "spago.yaml"
                , DOM.text
                    " — your package’s dependencies and pinned Registry package set. The starter includes prelude, effect, and console."
                ]
            , item [ inlineCode "src/Main.purs", DOM.text " — your application’s main module." ]
            , item [ inlineCode "test/Test/Main.purs", DOM.text " — a starter test module." ]
            , item
                [ inlineCode ".gitignore"
                , DOM.text " — keeps generated output and package caches out of Git."
                ]
            ]
        , paragraph
            [ DOM.text "Run the remaining commands from ", inlineCode "hello-iris", DOM.text "." ]
        ]
    }
  , { id: "write-your-program"
    , title: "Write your program"
    , body:
        [ paragraph
            [ DOM.text "Open "
            , inlineCode "src/Main.purs"
            , DOM.text " in your editor and replace the generated contents with:"
            ]
        , CodeBlock.codeBlock
            { code:
                "module Main where\n\nimport Prelude\n\nimport Effect (Effect)\nimport Effect.Console (log)\n\nmain :: Effect Unit\nmain = do\n  log \"Hello, Iris!\""
            , filename: "src/Main.purs"
            , highlight: []
            , language: CodeBlock.PureScript
            , lineNumbers: true
            , note: Nothing
            , surface: CodeBlock.Flat
            }
        , paragraph
            [ inlineCode "Main"
            , DOM.text
                " is the default entry-point module. The imports bring in the standard Prelude, the "
            , inlineCode "Effect"
            , DOM.text " type, and the console’s "
            , inlineCode "log"
            , DOM.text " function."
            ]
        , paragraph
            [ inlineCode "main :: Effect Unit"
            , DOM.text " says that main performs effects without returning a useful value. The "
            , inlineCode "do"
            , DOM.text " block contains the action that prints your greeting."
            ]
        ]
    }
  , { id: "compile-your-workspace"
    , title: "Compile your workspace"
    , body:
        [ paragraph [ DOM.text "Save your file and compile the workspace:" ]
        , Terminal.terminal
            [ { command: "iris build"
              , output:
                  "Reading Spago workspace configuration...\n\n✓ Selecting package to build: hello-iris\n\nDownloading dependencies...\nNo lockfile found, generating it...\nLockfile written to spago.lock. Please commit this file."
              }
            ]
        , paragraph
            [ DOM.text
                "Spago fetches the dependencies, then Iris type-checks and compiles your source to JavaScript in "
            , inlineCode "output/"
            , DOM.text ". Your main module becomes "
            , inlineCode "output/Main/index.js"
            , DOM.text
                ". The first build needs network access; later builds reuse cached packages and incremental compiler results."
            ]
        ]
    }
  , { id: "run-your-application"
    , title: "Run your application"
    , body:
        [ paragraph [ DOM.text "Run the application with Node.js:" ]
        , Terminal.terminal
            [ { command: "iris run"
              , output:
                  "Reading Spago workspace configuration...\n\n✓ Selecting package to build: hello-iris\n\nDownloading dependencies...\nHello, Iris!"
              }
            ]
        , paragraph
            [ inlineCode "iris run"
            , DOM.text " builds the workspace before calling the "
            , inlineCode "main"
            , DOM.text " function in "
            , inlineCode "Main"
            , DOM.text ". Your greeting appears after the build messages."
            ]
        , paragraph
            [ DOM.text
                "That’s your first Iris application. Change the greeting, save the file, and run "
            , inlineCode "iris run"
            , DOM.text " again to compile and execute the change."
            ]
        ]
    }
  , { id: "next-steps"
    , title: "Where to go next"
    , body:
        [ DOM.ul
            styleProps.list
            [ item
                [ DOM.strong {} "Keep compiling as you edit. "
                , DOM.text "Run "
                , inlineCode "iris watch"
                , DOM.text
                    " in another terminal to rebuild on save. It compiles changes but doesn’t rerun your application."
                ]
            , item
                [ DOM.strong {} "Explore the CLI. "
                , DOM.text "Run "
                , inlineCode "iris --help"
                , DOM.text " or "
                , inlineCode "iris run --help"
                , DOM.text " to see available commands and options."
                ]
            , item
                [ DOM.strong {} "Find a library. "
                , DOM.text "Browse packages, modules, and type signatures on "
                , link "https://pursuit.purescript.org" "Pursuit"
                , DOM.text "."
                ]
            ]
        ]
    }
  ]

paragraph :: Array JSX -> JSX
paragraph = DOM.p styleProps.paragraph

inlineCode :: String -> JSX
inlineCode = DOM.code styleProps.inlineCode

link :: String -> String -> JSX
link href label = DOM.a { className: styleProps.link.className, href } label

item :: Array JSX -> JSX
item = DOM.li {}
