module Website.Playground.Types
  ( Actions
  , Available
  , File
  , Line
  , Packages
  , Run
  , Server
  , StackFrame
  , State
  , Template
  , View
  , Viewer
  )
  where

import Prelude

import Data.Nullable (Nullable)
import Effect (Effect)
import React.Basic (Ref)
import Web.DOM.Element (Element)

-- | What the playground's controller publishes. The UI renders it and calls `Actions`; it never
-- | sees the editor, the language server or the runner.
-- | `phase` is `loading` until the packages and the language server are ready and the editor
-- | exists, `failed` when that did not work, and `ready` from then on.
type State =
  { phase :: String
  , files :: Array File
  , open :: Array String
  , active :: Nullable String
  , viewing :: Nullable Viewer
  , sidebar :: Boolean
  -- | The sidebar's width in pixels, which the reader sets by dragging its edge.
  , sidebarWidth :: Int
  -- | Whether the Output and Packages panel shows.
  , panel :: Boolean
  -- | The panel's width beside the editor and its height below it, in pixels, which the reader
  -- | sets by dragging its edge.
  , panelWidth :: Int
  , panelHeight :: Int
  -- | The panel's selected tab, `output`, `javascript` or `packages`, kept while closed.
  , panelTab :: String
  -- | Whether the console over a program's view shows its messages or only its bar, and its
  -- | height there in pixels, or 0 before the reader resizes it.
  , console :: Boolean
  , consoleHeight :: Int
  , server :: Server
  , packages :: Packages
  , run :: Run
  -- | Whether stack frames and the JavaScript tab use source maps, which applies to every tab.
  , sourceMaps :: Boolean
  -- | Whether the project changed since the last run, so its stack frames no longer navigate.
  , outputStale :: Boolean
  -- | The JavaScript tab: its `status` (`idle`, `loading`, `ready`, `stale` or `unavailable`) with
  -- | a message to show, empty when there is none, and whether its output has mappings.
  , generated :: { status :: String, message :: String, mapped :: Boolean }
  , templates :: Array Template
  , shared :: Boolean
  }

-- | A project file, such as `src/Main.purs`, with its diagnostic counts.
type File = { path :: String, errors :: Int, warnings :: Int }

-- | A read-only package or Prim source that navigation opened.
type Viewer = { uri :: String, label :: String }

-- | `kind` is `iris` or `mock`; `status` is `starting`, `ready`, `restarting` or `failed`. `version`
-- | is the Iris release, such as `v0.1.12`, and `revision` its commit.
type Server =
  { kind :: Nullable String
  , version :: Nullable String
  , revision :: Nullable String
  , status :: String
  , message :: Nullable String
  }

-- | The package set, whose `active` packages the project can import. `loaded` of `total` active
-- | packages, and `bytes` of `totalBytes` compressed, have been downloaded or read from the cache
-- | since the language server last started.
type Packages =
  { available :: Array Available
  , active :: Int
  , packageSet :: Nullable String
  , loaded :: Int
  , total :: Int
  , bytes :: Int
  , totalBytes :: Int
  }

-- | `status` is `active` for a package the project activated, `dependency` for one that an active
-- | package needs, listed in `requiredBy`, `installed` for an inactive package in the cache, and
-- | `available` for one that activating would download.
type Available = { name :: String, version :: String, status :: String, requiredBy :: String }

-- | `status` is `idle`, `compiling`, `running`, `done`, `stopped` or `failed`. A line's `kind` is
-- | `log`, `info`, `warning` or `error`. `view` is true once the program renders into its
-- | document, such as a Halogen or React application, which then runs until it is stopped and
-- | shows in the Output panel above its log.
type Run = { status :: String, lines :: Array Line, view :: Boolean }

type Line = { kind :: String, text :: String, frames :: Nullable (Array StackFrame) }

type StackFrame = { text :: String, uri :: String, line :: Int, column :: Int, mapped :: Boolean }

-- | A starting project that replaces the current one, such as `halogen`.
type Template = { id :: String, name :: String, description :: String }

type Actions =
  { openFile :: String -> Effect Unit
  -- | Closes a file's tab; the file stays in the project.
  , closeFile :: String -> Effect Unit
  , closeViewer :: Effect Unit
  , toggleSidebar :: Effect Unit
  -- | Opens the sidebar at a width in pixels.
  , resizeSidebar :: Int -> Effect Unit
  , closeSidebar :: Effect Unit
  , togglePanel :: Effect Unit
  -- | Opens the panel at a width and height in pixels.
  , resizePanel :: { width :: Int, height :: Int } -> Effect Unit
  , closePanel :: Effect Unit
  , selectPanelTab :: String -> Effect Unit
  , toggleSourceMaps :: Effect Unit
  , openFrame :: StackFrame -> Effect Unit
  -- | Collapses the console over a program's view to its bar, or brings it back up.
  , toggleConsole :: Effect Unit
  -- | Opens the console over a program's view at a height in pixels.
  , resizeConsole :: Int -> Effect Unit
  , closeConsole :: Effect Unit
  , createFile :: Effect Unit
  -- | Returns why the name was rejected, or null once the file is renamed.
  , renameFile :: String -> String -> Effect (Nullable String)
  , deleteFile :: String -> Effect Unit
  , run :: Effect Unit
  , stop :: Effect Unit
  , clearOutput :: Effect Unit
  , share :: Effect Unit
  -- | Replaces the project with a template, by its `id`.
  , loadTemplate :: String -> Effect Unit
  -- | Activates or deactivates a package by name, which restarts the language server.
  , activatePackage :: String -> Effect Unit
  , deactivatePackage :: String -> Effect Unit
  -- | Replaces the project with the first template.
  , reset :: Effect Unit
  , retry :: Effect Unit
  }

type View =
  { state :: State
  , actions :: Actions
  , editor :: Ref (Nullable Element)
  , generated :: Ref (Nullable Element)
  , frames :: Ref (Nullable Element)
  }
