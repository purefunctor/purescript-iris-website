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

type State =
  { phase :: String
  , files :: Array File
  , open :: Array String
  , active :: Nullable String
  , viewing :: Nullable Viewer
  , sidebar :: Boolean
  , sidebarWidth :: Int
  , panel :: Boolean
  , panelWidth :: Int
  , panelHeight :: Int
  , panelTab :: String
  , console :: Boolean
  , consoleHeight :: Int
  , server :: Server
  , packages :: Packages
  , run :: Run
  , sourceMaps :: Boolean
  , outputStale :: Boolean
  , generated :: { status :: String, message :: String, mapped :: Boolean }
  , templates :: Array Template
  , shared :: Boolean
  }

type File = { path :: String, errors :: Int, warnings :: Int }

type Viewer = { uri :: String, label :: String }

type Server =
  { kind :: Nullable String
  , version :: Nullable String
  , revision :: Nullable String
  , status :: String
  , message :: Nullable String
  }

type Packages =
  { available :: Array Available
  , active :: Int
  , packageSet :: Nullable String
  , loaded :: Int
  , total :: Int
  , bytes :: Int
  , totalBytes :: Int
  }

type Available = { name :: String, version :: String, status :: String, requiredBy :: String }

type Run = { status :: String, lines :: Array Line, view :: Boolean }

type Line = { kind :: String, text :: String, frames :: Nullable (Array StackFrame) }

type StackFrame = { text :: String, uri :: String, line :: Int, column :: Int, mapped :: Boolean }

type Template = { id :: String, name :: String, description :: String }

type Actions =
  { openFile :: String -> Effect Unit
  , closeFile :: String -> Effect Unit
  , closeViewer :: Effect Unit
  , toggleSidebar :: Effect Unit
  , resizeSidebar :: Int -> Effect Unit
  , closeSidebar :: Effect Unit
  , togglePanel :: Effect Unit
  , resizePanel :: { width :: Int, height :: Int } -> Effect Unit
  , closePanel :: Effect Unit
  , selectPanelTab :: String -> Effect Unit
  , toggleSourceMaps :: Effect Unit
  , openFrame :: StackFrame -> Effect Unit
  , toggleConsole :: Effect Unit
  , resizeConsole :: Int -> Effect Unit
  , closeConsole :: Effect Unit
  , createFile :: Effect Unit
  , renameFile :: String -> String -> Effect (Nullable String)
  , deleteFile :: String -> Effect Unit
  , run :: Effect Unit
  , stop :: Effect Unit
  , clearOutput :: Effect Unit
  , share :: Effect Unit
  , loadTemplate :: String -> Effect Unit
  , activatePackage :: String -> Effect Unit
  , deactivatePackage :: String -> Effect Unit
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
