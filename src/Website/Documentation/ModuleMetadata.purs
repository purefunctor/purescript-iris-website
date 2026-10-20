module Website.Documentation.ModuleMetadata (component) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactComponent)
import React.Basic.Hooks as Hooks
import Website.Components.CodeBlock as CodeBlock
import Website.Components.Documentation as Documentation
import Website.Documentation.Prose (inlineCode, item, list, note, paragraph)
import Yoga.React.DOM as DOM

component :: ReactComponent {}
component = unsafePerformEffect $ Hooks.reactComponent "ModuleMetadata" \_ ->
  pure $ Documentation.documentation
    { page: Documentation.ModuleMetadata
    , intro:
        [ paragraph
            [ DOM.text
                "Next to each module's generated JavaScript, Iris writes a metadata.json file. It records the package the module belongs to, whether that package is editable, where the module's source file is, and the name of its foreign file. Tools such as bundler plugins can read it instead of guessing which package a module comes from."
            ]
        ]
    , sections
    }

-- | A list item that describes a metadata field.
field :: String -> Array JSX -> JSX
field name description = item ([ inlineCode name, DOM.text " " ] <> description)

sections :: Array Documentation.Section
sections =
  [ { id: "where-the-metadata-lives"
    , title: "Where the metadata lives"
    , body:
        [ note
            [ DOM.strong {} "Requires Iris 0.1.8 or later"
            , DOM.p {} [ DOM.text "Iris 0.1.7 and earlier do not write module metadata." ]
            ]
        , paragraph
            [ DOM.text "The build that writes "
            , inlineCode "output/<Module>/index.js"
            , DOM.text " also writes "
            , inlineCode "output/<Module>/metadata.json"
            , DOM.text ". For a module named "
            , inlineCode "Library.Types"
            , DOM.text ", that is "
            , inlineCode "output/Library.Types/metadata.json"
            , DOM.text "."
            ]
        , paragraph
            [ DOM.text
                "Only modules that a build compiled have a record. A module that no build has compiled has no directory, so a missing file means that Iris hasn't compiled the module. The "
            , inlineCode "Prim"
            , DOM.text " modules never have records."
            ]
        , paragraph
            [ DOM.text
                "There is no file that lists every module, so start from the module you want and read its record."
            ]
        ]
    }
  , { id: "when-iris-writes-it"
    , title: "When Iris writes it"
    , body:
        [ paragraph
            [ inlineCode "iris build"
            , DOM.text ", "
            , inlineCode "iris run"
            , DOM.text ", "
            , inlineCode "iris test"
            , DOM.text ", and "
            , inlineCode "iris watch"
            , DOM.text " write the records beside the modules they compile, in "
            , inlineCode "output"
            , DOM.text " or in the directory that "
            , inlineCode "--output DIR"
            , DOM.text " names."
            ]
        , paragraph
            [ DOM.text
                "A build with errors writes nothing, so it leaves every earlier record as it was. If a write fails, Iris reports the error, and the module keeps its previous record, or stays without one, until a later build writes it. Iris writes records in parallel, so other records from the same build may already be replaced."
            ]
        , paragraph
            [ inlineCode "--package NAME"
            , DOM.text
                " limits what Iris compiles to that package and its dependencies, so it writes records only for modules in those packages. Records of other packages stay as they were. With "
            , inlineCode "--package"
            , DOM.text ", "
            , inlineCode "iris watch"
            , DOM.text " ignores new files outside the selected packages and their dependencies."
            ]
        ]
    }
  , { id: "stale-modules"
    , title: "Stale modules"
    , body:
        [ paragraph
            [ DOM.text "Neither "
            , inlineCode "iris build"
            , DOM.text " nor "
            , inlineCode "iris watch"
            , DOM.text
                " deletes anything in the output directory, so a module directory and its record may be stale: left there by an earlier build. After you delete or rename a module, its directory and its record stay behind, and nothing marks them as stale."
            ]
        , paragraph
            [ DOM.text "Don't list "
            , inlineCode "output"
            , DOM.text
                " to find modules, because that includes stale ones. Start at your entry module and follow its imports through the generated JavaScript instead. To clean up, delete the output directory and build again."
            ]
        ]
    }
  , { id: "reading-while-building"
    , title: "Reading while building"
    , body:
        [ paragraph
            [ DOM.text
                "Iris replaces each record atomically. It writes the new record to a temporary file in the module's directory and renames it over "
            , inlineCode "metadata.json"
            , DOM.text
                ", so a reader sees either the previous record or the new one, never a partial file. Iris skips a record whose content hasn't changed. The module's other files are written in place, so a reader can see them partially written while a build runs."
            ]
        , paragraph
            [ inlineCode "iris build"
            , DOM.text " and "
            , inlineCode "iris watch"
            , DOM.text
                " can write to the same output directory at the same time. Whichever finishes last leaves its records."
            ]
        ]
    }
  , { id: "schema"
    , title: "Schema"
    , body:
        [ paragraph
            [ DOM.text "Here is the record for a module in a workspace package named "
            , inlineCode "library"
            , DOM.text ":"
            ]
        , CodeBlock.codeBlock
            { code: example
            , filename: "output/Library/metadata.json"
            , highlight: []
            , language: CodeBlock.JSON
            , lineNumbers: false
            , note: Nothing
            , surface: CodeBlock.Flat
            }
        , paragraph
            [ DOM.text
                "The record is indented JSON. It has no timestamp or build counter, so the same module and Iris version always produce the same record. Its fields are:"
            ]
        , list
            [ field "version"
                [ DOM.text
                    "is the schema version, currently 1. It only changes when a change could break existing readers, so check it first."
                ]
            , field "iris"
                [ DOM.text "is the version of Iris that wrote the record, as "
                , inlineCode "iris --version"
                , DOM.text " prints it, including suffixes like "
                , inlineCode "0.1.8-dev.0123abc"
                , DOM.text "."
                ]
            , field "package"
                [ DOM.text "is the name of the package that owns the module's source file." ]
            , field "editable"
                [ DOM.text "is "
                , inlineCode "true"
                , DOM.text " for workspace and local packages, and "
                , inlineCode "false"
                , DOM.text " for registry and git packages."
                ]
            , field "source"
                [ DOM.text
                    "is the absolute path of the PureScript source file, in the platform's native format."
                ]
            , field "foreign"
                [ DOM.text
                    "is the name of the foreign module in the module's output directory, such as "
                , inlineCode "foreign.js"
                , DOM.text " or "
                , inlineCode "foreign.jsx"
                , DOM.text ", or "
                , inlineCode "null"
                , DOM.text " if the module doesn't import foreign values."
                ]
            ]
        , paragraph
            [ DOM.text
                "The record doesn't list the module's imports. Read them from the generated JavaScript. It also says nothing about diagnostics."
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
                " directory. Two files that declare the same module name are also an error, because they would write the same output files."
            ]
        ]
    }
  ]

example :: String
example = """{
  "version": 1,
  "iris": "0.1.8",
  "package": "library",
  "editable": true,
  "source": "/home/user/project/packages/library/src/Library.purs",
  "foreign": "foreign.js"
}"""
