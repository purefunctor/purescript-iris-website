module Website.Playground.Types
  ( Actions
  , Available
  , File
  , Line
  , Packages
  , Run
  , Server
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
  -- | The panel's selected tab, `output` or `packages`, which it keeps while closed.
  , panelTab :: String
  , server :: Server
  , packages :: Packages
  , run :: Run
  , templates :: Array Template
  , shared :: Boolean
  }

-- | A project file, such as `src/Main.purs`, with its diagnostic counts.
type File = { path :: String, errors :: Int, warnings :: Int }

-- | A read-only package or Prim source that navigation opened.
type Viewer = { uri :: String, label :: String }

-- | `kind` is `iris` or `mock`; `status` is `starting`, `ready`, `restarting` or `failed`. `version`
-- | is the Iris release, such as `v0.1.9`, and `revision` its commit.
type Server =
  { kind :: Nullable String
  , version :: Nullable String
  , revision :: Nullable String
  , status :: String
  , message :: Nullable String
  }

-- | The package set, which the project can import from in full. `loaded` of `total` packages, and
-- | `bytes` of `totalBytes` compressed, have been downloaded or read from the cache.
type Packages =
  { available :: Array Available
  , packageSet :: Nullable String
  , loaded :: Int
  , total :: Int
  , bytes :: Int
  , totalBytes :: Int
  }

type Available = { name :: String, version :: String }

-- | `status` is `idle`, `compiling`, `running`, `done`, `stopped` or `failed`. A line's `kind` is
-- | `log`, `info`, `warning` or `error`. `view` is true once the program renders into its
-- | document, such as a Halogen or React application, which then runs until it is stopped and
-- | shows in the Output panel above its log.
type Run = { status :: String, lines :: Array Line, view :: Boolean }

type Line = { kind :: String, text :: String }

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
  -- | Replaces the project with the first template.
  , reset :: Effect Unit
  , retry :: Effect Unit
  }

type View =
  { state :: State
  , actions :: Actions
  , editor :: Ref (Nullable Element)
  , frames :: Ref (Nullable Element)
  }
