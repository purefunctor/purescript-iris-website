module Website.Documentation.GettingStarted (component) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Hooks as Hooks
import Website.Components.CodeBlock as CodeBlock
import Website.Components.Documentation as Documentation
import Website.Components.Installation as Installation
import Website.Components.Terminal as Terminal
import Website.Documentation.Prose (inlineCode, item, link, list, note, paragraph)
import Yoga.React.DOM as DOM

component :: ReactComponent {}
component = unsafePerformEffect $ Hooks.reactComponent "GettingStarted" \_ ->
  pure $ Documentation.documentation
    { page: Documentation.GettingStarted
    , intro:
        "This guide covers installing Iris, creating a project, and running a small program that prints a greeting."
    , sections
    }

sections :: Array Documentation.Section
sections =
  [ { id: "before-you-begin"
    , title: "Before you begin"
    , body:
        [ paragraph [ DOM.text "You need the following before you begin:" ]
        , list
            [ item
                [ link "https://nodejs.org/en/download" "Node.js"
                , DOM.text " 22.5.0 or later, which runs your compiled program and includes npm"
                ]
            , item [ link "https://git-scm.com/downloads" "Git" ]
            , item
                [ link "https://github.com/purescript/spago" "Spago"
                , DOM.text ", the PureScript package manager, which Iris uses to download libraries"
                ]
            , item
                [ DOM.text
                    "An internet connection, so that Spago can download packages during the first build"
                ]
            ]
        , paragraph [ DOM.text "If Spago is not installed, install it with npm:" ]
        , Terminal.terminal [ { command: "npm install --global spago@1.0.4", output: "" } ]
        , paragraph [ DOM.text "Then verify that each tool is available on your PATH:" ]
        , Terminal.terminal
            [ { command: "node --version", output: "v22.23.3" }
            , { command: "git --version", output: "git version 2.55.0" }
            , { command: "spago --version", output: "1.0.4" }
            ]
        , paragraph
            [ DOM.text
                "Please note that the version numbers in this guide are not updated in real time."
            ]
        , paragraph
            [ DOM.text "The official PureScript compiler, "
            , inlineCode "purs"
            , DOM.text
                ", is not required. Iris compiles your code in its place and handles the compiler version check that Spago performs."
            ]
        ]
    }
  , { id: "install-iris"
    , title: "Install Iris"
    , body:
        [ paragraph
            [ DOM.text
                "Iris provides an install script for each platform. Select your platform and run the command in a terminal:"
            ]
        , Installation.installation { fill: true }
        , paragraph
            [ DOM.text
                "The script downloads the latest stable release from GitHub and installs the "
            , inlineCode "iris"
            , DOM.text
                " executable. To review the script before running it, select \"Show source\"."
            ]
        , paragraph
            [ DOM.text "If the "
            , link "https://cli.github.com/" "GitHub CLI"
            , DOM.text " ("
            , inlineCode "gh"
            , DOM.text
                ") is installed, the script uses it to verify that the release was built from the Iris repository. Otherwise, the script prints a warning and installs Iris without verification."
            ]
        , paragraph [ DOM.text "After the script finishes, verify the installation:" ]
        , Terminal.terminal [ { command: "iris --version", output: "iris 0.1.8" } ]
        , paragraph
            [ DOM.text
                "If the command prints a version number, Iris is ready to use. If your shell cannot find the command, follow the steps below."
            ]
        , note
            [ DOM.strong {} "If your shell cannot find Iris"
            , DOM.p {}
                [ DOM.text
                    "The install script does not modify your PATH. If the installation directory is not already on your PATH, the script prints a reminder, and you must add the directory yourself."
                ]
            , DOM.p {}
                [ DOM.text "On macOS and Linux, Iris is installed in "
                , inlineCode "~/.local/bin"
                , DOM.text
                    ". Run the following command to add it to your PATH for the current session:"
                ]
            , Terminal.terminal
                [ { command: "export PATH=\"$HOME/.local/bin:$PATH\"", output: "" } ]
            , DOM.p {}
                [ DOM.text
                    "To make the change permanent, add the same line to your shell's startup file, such as "
                , inlineCode "~/.bashrc"
                , DOM.text " or "
                , inlineCode "~/.zshrc"
                , DOM.text "."
                ]
            , DOM.p {}
                [ DOM.text "On Windows, Iris is installed in "
                , inlineCode "%LOCALAPPDATA%\\Iris\\bin"
                , DOM.text
                    ". Add this directory to your user Path environment variable, and then open a new PowerShell window."
                ]
            ]
        , paragraph
            [ DOM.text
                "To install a specific version or use a different installation directory, see "
            , link "/docs/installation/" "Installation"
            , DOM.text "."
            ]
        ]
    }
  , { id: "create-a-workspace"
    , title: "Create a workspace"
    , body:
        [ paragraph
            [ DOM.text "With Iris installed, create a new directory for your project and run "
            , inlineCode "iris new"
            , DOM.text " inside it:"
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
            [ inlineCode "iris new"
            , DOM.text
                " sets up a Spago workspace in the current directory and names the package after the directory. It does not create a project inside an existing Spago workspace, so the new directory must not be nested in one."
            ]
        , paragraph
            [ DOM.text
                "The workspace is also assigned a package set, which is a list of package versions from the PureScript Registry that are known to work together. Iris selects the newest package set that it supports, so the version in your output may be higher than 81.3.0."
            ]
        , paragraph [ inlineCode "iris new", DOM.text " creates the following files:" ]
        , list
            [ item
                [ inlineCode "spago.yaml"
                , DOM.text
                    " describes your package, including its dependencies and the package set it uses. The starter package depends on "
                , inlineCode "prelude"
                , DOM.text ", "
                , inlineCode "effect"
                , DOM.text ", and "
                , inlineCode "console"
                , DOM.text "."
                ]
            , item [ inlineCode "src/Main.purs", DOM.text " is the main module of your program." ]
            , item
                [ inlineCode "test/Test/Main.purs"
                , DOM.text " is the main module of your test suite."
                ]
            , item
                [ inlineCode ".gitignore"
                , DOM.text " excludes the compiled code in "
                , inlineCode "output"
                , DOM.text " and the downloaded packages in "
                , inlineCode ".spago"
                , DOM.text " from Git."
                ]
            ]
        , paragraph
            [ DOM.text "Run the remaining commands in this guide from the "
            , inlineCode "hello-iris"
            , DOM.text " directory."
            ]
        ]
    }
  , { id: "write-your-program"
    , title: "Write your program"
    , body:
        [ paragraph
            [ DOM.text "Open "
            , inlineCode "src/Main.purs"
            , DOM.text " in your editor and replace its contents with the following:"
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
            [ DOM.text "The first line declares the module "
            , inlineCode "Main"
            , DOM.text ". By default, "
            , inlineCode "iris run"
            , DOM.text
                " starts the program from this module. To use a different module, pass it with "
            , inlineCode "iris run --main"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text "The imports include "
            , inlineCode "Prelude"
            , DOM.text
                ", which provides the basic types and functions used by most PureScript code, along with the "
            , inlineCode "Effect"
            , DOM.text " type and the "
            , inlineCode "log"
            , DOM.text " function for printing to the console."
            ]
        , paragraph
            [ DOM.text "The line "
            , inlineCode "main :: Effect Unit"
            , DOM.text " is a type signature. It states that "
            , inlineCode "main"
            , DOM.text
                " is an action that can have side effects, such as printing text, and that it does not return a meaningful value. The "
            , inlineCode "do"
            , DOM.text " block contains the steps that "
            , inlineCode "main"
            , DOM.text " performs. In this program, it is a single call to "
            , inlineCode "log"
            , DOM.text " that prints the greeting."
            ]
        ]
    }
  , { id: "compile-your-workspace"
    , title: "Compile your workspace"
    , body:
        [ paragraph [ DOM.text "Save the file and build the project:" ]
        , Terminal.terminal
            [ { command: "iris build"
              , output:
                  "Reading Spago workspace configuration...\n\n✓ Selecting package to build: hello-iris\n\nDownloading dependencies...\nNo lockfile found, generating it...\nLockfile written to spago.lock. Please commit this file."
              }
            ]
        , paragraph
            [ DOM.text
                "The first build takes longer because Spago downloads your dependencies. Spago also creates "
            , inlineCode "spago.lock"
            , DOM.text
                ", which records the exact version of every package. Commit this file so that everyone working on the project builds with the same versions."
            ]
        , paragraph
            [ DOM.text
                "Once the dependencies are available, Iris checks your code for type errors and compiles it to JavaScript in the "
            , inlineCode "output"
            , DOM.text " directory. The "
            , inlineCode "Main"
            , DOM.text " module is written to "
            , inlineCode "output/Main/index.js"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text
                "Subsequent builds are faster. Spago reuses the packages it has already downloaded, and Iris recompiles only the modules affected by your changes."
            ]
        ]
    }
  , { id: "run-your-application"
    , title: "Run your application"
    , body:
        [ paragraph [ DOM.text "To run the program, use ", inlineCode "iris run", DOM.text ":" ]
        , Terminal.terminal
            [ { command: "iris run"
              , output:
                  "Reading Spago workspace configuration...\n\n✓ Selecting package to build: hello-iris\n\nDownloading dependencies...\nHello, Iris!"
              }
            ]
        , paragraph
            [ inlineCode "iris run"
            , DOM.text
                " builds the project first, so the output begins with the same build messages. It then runs the "
            , inlineCode "main"
            , DOM.text " function from the "
            , inlineCode "Main"
            , DOM.text " module with Node.js, and the greeting is printed at the end."
            ]
        , paragraph
            [ DOM.text "If you change the greeting and run "
            , inlineCode "iris run"
            , DOM.text " again, Iris rebuilds the changed module and prints the new message."
            ]
        ]
    }
  , { id: "next-steps"
    , title: "Where to go next"
    , body:
        [ list
            [ item
                [ DOM.text
                    "To get types, completion, and error messages in your editor, install the Visual Studio Code extension or connect another editor to the "
                , link "/docs/language-server/" "Iris language server"
                , DOM.text "."
                ]
            , item
                [ DOM.text "Run "
                , inlineCode "iris watch"
                , DOM.text
                    " in a separate terminal while you work. It rebuilds the project whenever you save a file but does not run the program."
                ]
            , item
                [ DOM.text "Run "
                , inlineCode "iris --help"
                , DOM.text " to list all commands. Each command also has its own help, such as "
                , inlineCode "iris run --help"
                , DOM.text "."
                ]
            , item
                [ DOM.text "Search for libraries on "
                , link "https://pursuit.purescript.org" "Pursuit"
                , DOM.text ", which indexes packages, modules, and type signatures."
                ]
            ]
        ]
    }
  ]
