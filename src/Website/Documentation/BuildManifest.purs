module Website.Documentation.BuildManifest (component) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactComponent)
import React.Basic.Hooks as Hooks
import Website.Components.CodeBlock as CodeBlock
import Website.Components.Documentation as Documentation
import Website.Documentation.Prose (inlineCode, item, list, paragraph)
import Yoga.React.DOM as DOM

component :: ReactComponent {}
component =
  unsafePerformEffect
    $ Hooks.reactComponent
        "BuildManifest"
        \_ ->
          pure
            $ Documentation.documentation
                { page: Documentation.BuildManifest
                , intro:
                    "After every successful build, Iris writes output/manifest.json. It lists the workspace's packages and their dependencies, every module in those packages, the package each module belongs to, and where each module's source and output files are. Tools such as bundler plugins can read it instead of scanning the output directory and guessing which package a module comes from."
                , sections
                }

-- | A list item that describes a manifest field.
field :: String -> Array JSX -> JSX
field name description = item ([ inlineCode name, DOM.text " " ] <> description)

sections :: Array Documentation.Section
sections =
  [ { id: "what-the-manifest-describes"
    , title: "What the manifest describes"
    , body:
        [ paragraph
            [ DOM.text
                "The manifest lists every package in the Spago workspace, their dependencies, and every module in them. Iris reads each module's entry from its source file without compiling it, so the manifest covers the whole workspace even when a build compiles only part of it."
            ]
        , paragraph
            [ DOM.text
                "It describes where Iris writes each module, not which modules a build compiled. After a successful build of the whole workspace, every file it lists exists and is up to date."
            ]
        ]
    }
  , { id: "when-iris-writes-the-manifest"
    , title: "When Iris writes the manifest"
    , body:
        [ paragraph
            [ inlineCode "iris build"
            , DOM.text ", "
            , inlineCode "iris run"
            , DOM.text ", "
            , inlineCode "iris test"
            , DOM.text ", and "
            , inlineCode "iris watch"
            , DOM.text " write "
            , inlineCode "output/manifest.json"
            , DOM.text " after every successful build, or "
            , inlineCode "DIR/manifest.json"
            , DOM.text " with "
            , inlineCode "--output DIR"
            , DOM.text
                ". Iris never uses the contents of an existing manifest. It only compares them with the new manifest to decide whether to rewrite the file."
            ]
        , paragraph
            [ DOM.text
                "Iris writes the compiled modules first, and skips files whose content hasn't changed. Then it writes the manifest to a temporary file and renames it over "
            , inlineCode "manifest.json"
            , DOM.text
                ", so readers never see a partial file. The temporary file's name starts with "
            , inlineCode ".manifest-"
            , DOM.text ". If nothing changed, Iris doesn't rewrite the manifest."
            ]
        , paragraph
            [ DOM.text
                "A build with errors writes nothing, and neither does a build with no input files. If a write fails partway, Iris deletes "
            , inlineCode "manifest.json"
            , DOM.text " and reports the error. The next successful build writes it again."
            ]
        ]
    }
  , { id: "building-one-package"
    , title: "Building one package"
    , body:
        [ paragraph
            [ inlineCode "--package NAME"
            , DOM.text
                " limits what Iris compiles to that package and its dependencies. The manifest still lists the whole workspace, and output from earlier builds of other packages stays in place."
            ]
        , paragraph
            [ DOM.text "Iris runs "
            , inlineCode "spago fetch"
            , DOM.text " for the whole workspace even with "
            , inlineCode "--package"
            , DOM.text ", because the manifest needs every package's sources."
            ]
        , paragraph
            [ DOM.text "With "
            , inlineCode "--package"
            , DOM.text ", "
            , inlineCode "iris watch"
            , DOM.text
                " rebuilds when the selected packages change. If you add, remove, or rename a module in another package, it rewrites the manifest without compiling that package."
            ]
        ]
    }
  , { id: "missing-and-stale-files"
    , title: "Missing and stale files"
    , body:
        [ paragraph
            [ DOM.text
                "A module that hasn't been compiled yet is listed, but its files don't exist. A module compiled by an earlier build keeps its files, which may be out of date. Check that a file exists before reading it, and use "
            , inlineCode "iris watch query"
            , DOM.text " to check whether the output matches the sources."
            ]
        , paragraph
            [ DOM.text "Neither "
            , inlineCode "iris build"
            , DOM.text " nor "
            , inlineCode "iris watch"
            , DOM.text
                " deletes anything in the output directory. Files from deleted or renamed modules stay behind, so ignore any file the manifest doesn't list. To clean up, delete the output directory and build again."
            ]
        , paragraph
            [ inlineCode "iris run"
            , DOM.text " and "
            , inlineCode "iris test"
            , DOM.text
                " only run a main module that the current build compiled, so they never run a missing or stale module."
            ]
        ]
    }
  , { id: "what-readers-can-rely-on"
    , title: "What readers can rely on"
    , body:
        [ list
            [ item
                [ DOM.text
                    "The manifest describes the whole workspace as of the last successful build, and one Iris version wrote it."
                ]
            , item
                [ DOM.text "Every module's "
                , inlineCode "package"
                , DOM.text ", and every name in a package's "
                , inlineCode "dependencies"
                , DOM.text ", is a key in "
                , inlineCode "packages"
                , DOM.text "."
                ]
            , item [ DOM.text "No two modules share a name, so no two modules share output files." ]
            , item
                [ DOM.text
                    "After a successful build of the whole workspace, every listed file exists."
                ]
            ]
        , paragraph
            [ DOM.text
                "No manifest means no successful build has been recorded. The manifest says nothing about diagnostics."
            ]
        , paragraph
            [ inlineCode "iris build"
            , DOM.text " and "
            , inlineCode "iris watch"
            , DOM.text
                " can write to the same output directory at the same time. Whichever finishes last leaves its manifest."
            ]
        ]
    }
  , { id: "schema"
    , title: "Schema"
    , body:
        [ paragraph
            [ DOM.text "Here is the manifest for a workspace where "
            , inlineCode "application"
            , DOM.text " depends on "
            , inlineCode "library"
            , DOM.text ":"
            ]
        , CodeBlock.codeBlock
            { code: example
            , filename: "output/manifest.json"
            , highlight: []
            , language: CodeBlock.JSON
            , lineNumbers: false
            , note: Nothing
            , surface: CodeBlock.Flat
            }
        , paragraph
            [ DOM.text "The manifest is indented JSON. The keys of "
            , inlineCode "packages"
            , DOM.text " and "
            , inlineCode "modules"
            , DOM.text
                ", and all lists, are sorted. There's no timestamp, build counter, or record of the selected packages, so the same workspace and Iris version always produce the same manifest."
            ]
        , paragraph [ DOM.text "Top-level fields:" ]
        , list
            [ field
                "version"
                [ DOM.text
                    "is the schema version, currently 1. It only changes when a change could break existing readers, so check it first."
                ]
            , field
                "iris"
                [ DOM.text "is the version of Iris that wrote the manifest, as "
                , inlineCode "iris --version"
                , DOM.text " prints it, including suffixes like "
                , inlineCode "0.1.7-dev.0123abc"
                , DOM.text "."
                ]
            , field "workspace_root" [ DOM.text "is the Spago workspace root." ]
            , field "packages" [ DOM.text "maps package names to packages." ]
            , field "modules" [ DOM.text "maps module names to modules." ]
            ]
        ]
    }
  , { id: "packages"
    , title: "Packages"
    , body:
        [ paragraph
            [ inlineCode "packages"
            , DOM.text
                " lists every workspace package and all their dependencies, including packages with no modules. Each package has these fields:"
            ]
        , list
            [ field
                "editable"
                [ DOM.text "is "
                , inlineCode "true"
                , DOM.text " for workspace and local packages, and "
                , inlineCode "false"
                , DOM.text " for registry and git packages."
                ]
            , field "root" [ DOM.text "is the package directory." ]
            , field
                "dependencies"
                [ DOM.text
                    "lists the package's dependencies by name. For a workspace package with tests, it includes the test dependencies."
                ]
            ]
        ]
    }
  , { id: "modules"
    , title: "Modules"
    , body:
        [ paragraph
            [ inlineCode "modules"
            , DOM.text " lists every module in the workspace's packages. The built-in "
            , inlineCode "Prim"
            , DOM.text
                " modules never appear, and a file whose module header doesn't parse is left out until you fix it. Each module has these fields:"
            ]
        , list
            [ field "package" [ DOM.text "is the package that owns the module's source file." ]
            , field "source" [ DOM.text "is the PureScript source file." ]
            , field "javascript" [ DOM.text "is the generated module." ]
            , field
                "foreign"
                [ DOM.text "is the copied foreign module, such as "
                , inlineCode "Main/foreign.js"
                , DOM.text " or "
                , inlineCode "Main/foreign.jsx"
                , DOM.text ", or "
                , inlineCode "null"
                , DOM.text " if the module doesn't import foreign values."
                ]
            ]
        , paragraph
            [ DOM.text
                "The manifest doesn't record imports between modules. Read them from the generated JavaScript, which exists for every compiled module."
            ]
        ]
    }
  , { id: "paths"
    , title: "Paths"
    , body:
        [ paragraph
            [ inlineCode "workspace_root"
            , DOM.text ", package "
            , inlineCode "root"
            , DOM.text ", and module "
            , inlineCode "source"
            , DOM.text " are absolute paths in the platform's native format."
            ]
        , paragraph
            [ inlineCode "javascript"
            , DOM.text " and "
            , inlineCode "foreign"
            , DOM.text " are relative to the output directory and always use forward slashes."
            ]
        ]
    }
  , { id: "package-ownership"
    , title: "Package ownership"
    , body:
        [ paragraph
            [ DOM.text
                "A source file belongs to the package whose source globs match it. A package's globs are "
            , inlineCode "src/**/*.purs"
            , DOM.text " and "
            , inlineCode "test/**/*.purs"
            , DOM.text " under its root. Registry, git, and local packages have no "
            , inlineCode "test"
            , DOM.text " glob. "
            , inlineCode "iris watch"
            , DOM.text " uses the same rule for files you create while it runs."
            ]
        , paragraph
            [ DOM.text
                "A file that two packages match is an error. For example, that happens when one package's root is inside another package's "
            , inlineCode "src"
            , DOM.text
                " directory. Two files that declare the same module name are also an error, because they would write the same output files. Iris reports both errors before writing anything, even for packages it isn't compiling."
            ]
        ]
    }
  ]

example :: String
example =
  """{
  "version": 1,
  "iris": "0.1.7",
  "workspace_root": "/home/user/project",
  "packages": {
    "application": {
      "editable": true,
      "root": "/home/user/project",
      "dependencies": ["library"]
    },
    "library": {
      "editable": true,
      "root": "/home/user/project/packages/library",
      "dependencies": []
    }
  },
  "modules": {
    "Library": {
      "package": "library",
      "source": "/home/user/project/packages/library/src/Library.purs",
      "javascript": "Library/index.js",
      "foreign": "Library/foreign.js"
    },
    "Main": {
      "package": "application",
      "source": "/home/user/project/src/Main.purs",
      "javascript": "Main/index.js",
      "foreign": null
    }
  }
}"""
