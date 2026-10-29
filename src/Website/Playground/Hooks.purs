module Website.Playground.Hooks
  ( HandleProps
  , PresenceProps
  , Resizable
  , UseFollowOutput
  , UseFrameSlot
  , UsePanelBelowEditor
  , UsePlayground
  , UseResizable
  , UseTabListOverflow
  , useFollowOutput
  , useFrameSlot
  , usePanelBelowEditor
  , usePlayground
  , useResizable
  , useTabListOverflow
  )
  where

import Prelude

import Data.Nullable (Nullable)
import Effect (Effect)
import Foreign (Foreign)
import React.Basic (Ref)
import React.Basic.Events (EventHandler)
import React.Basic.Hooks (Hook, unsafeHook)
import Web.DOM.Element (Element)
import Website.Playground.Types (View)

foreign import data UsePlayground :: Type -> Type

foreign import data UseTabListOverflow :: Type -> Type

foreign import data UseFrameSlot :: Type -> Type

foreign import data UseResizable :: Type -> Type

foreign import data UsePanelBelowEditor :: Type -> Type

foreign import data UseFollowOutput :: Type -> Type

type PresenceProps =
  { "data-entering" :: Nullable Boolean
  , "data-exiting" :: Nullable Boolean
  , onAnimationEnd :: EventHandler
  }

type HandleProps =
  { "aria-controls" :: String
  , "aria-label" :: String
  , "aria-orientation" :: String
  , "aria-valuemax" :: Int
  , "aria-valuemin" :: Int
  , "aria-valuenow" :: Int
  , "aria-valuetext" :: String
  , "data-dragging" :: Nullable Boolean
  , onKeyDown :: EventHandler
  , onLostPointerCapture :: EventHandler
  , onPointerDown :: EventHandler
  , onPointerMove :: EventHandler
  , role :: String
  , tabIndex :: Int
  }

type Resizable =
  { shown :: Boolean
  , current :: Int
  , rendered :: Boolean
  , presenceProps :: PresenceProps
  , handleProps :: HandleProps
  }

usePlayground :: Foreign -> Hook UsePlayground View
usePlayground theme = unsafeHook (usePlaygroundImpl theme)

useTabListOverflow :: String -> Hook UseTabListOverflow (Ref (Nullable Element))
useTabListOverflow selected = unsafeHook (useTabListOverflowImpl selected)

useFrameSlot :: Ref (Nullable Element) -> Hook UseFrameSlot (Ref (Nullable Element))
useFrameSlot frames = unsafeHook (useFrameSlotImpl frames)

useResizable ::
  { id :: String
  , label :: String
  , open :: Boolean
  , size :: Int
  , min :: Int
  , max :: Int
  , collapse :: Int
  , vertical :: Boolean
  , fromEnd :: Boolean
  , share :: Number
  , resize :: Int -> Effect Unit
  , close :: Effect Unit
  } -> Hook UseResizable Resizable
useResizable options = unsafeHook (useResizableImpl options)

usePanelBelowEditor :: Hook UsePanelBelowEditor Boolean
usePanelBelowEditor = unsafeHook usePanelBelowEditorImpl

useFollowOutput ::
  Hook UseFollowOutput { scroller :: Ref (Nullable Element), onScroll :: EventHandler }
useFollowOutput = unsafeHook useFollowOutputImpl

foreign import usePlaygroundImpl :: Foreign -> Effect View

foreign import useTabListOverflowImpl :: String -> Effect (Ref (Nullable Element))

foreign import useFrameSlotImpl :: Ref (Nullable Element) -> Effect (Ref (Nullable Element))

foreign import useResizableImpl ::
  { id :: String
  , label :: String
  , open :: Boolean
  , size :: Int
  , min :: Int
  , max :: Int
  , collapse :: Int
  , vertical :: Boolean
  , fromEnd :: Boolean
  , share :: Number
  , resize :: Int -> Effect Unit
  , close :: Effect Unit
  } -> Effect Resizable

foreign import usePanelBelowEditorImpl :: Effect Boolean

foreign import useFollowOutputImpl ::
  Effect { scroller :: Ref (Nullable Element), onScroll :: EventHandler }
