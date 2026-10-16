module Website.Components.Backdrop (component) where

import Prelude

import Data.Foldable (for_)
import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, Ref)
import React.Basic.Hooks as Hooks
import Web.DOM.Element (Element)
import Yoga.React.DOM as DOM

type Field = { ripple :: Ref (Nullable Element) -> Effect Unit, stop :: Effect Unit }

foreign import startField :: Ref (Nullable Element) -> Effect Field

styles = StyleX.create
  { root:
      { backgroundColor: "var(--bg-canvas)"
      , backgroundImage: "var(--canvas-texture)"
      , isolation: "isolate"
      , overflow: "hidden"
      , position: "relative"
      }
  , layer: { inset: 0, pointerEvents: "none", position: "absolute", zIndex: 0 }
  -- The field fades out over its bottom 22% so the canvas texture continues beneath it.
  , canvas:
      { height: "100%"
      , inset: 0
      , maskImage: "linear-gradient(black 78%, transparent)"
      , position: "absolute"
      , width: "100%"
      }
  , content: { position: "relative", zIndex: 1 }
  }

styleProps = StyleX.recordProps styles

-- | The brand's animated dot field, with a clearing in the top-left corner behind the copy.
-- | Incrementing `ripples` sends a ripple through the field from the centre of `rippleOrigin`.
component ::
  ReactComponent { content :: Array JSX, rippleOrigin :: Ref (Nullable Element), ripples :: Int }
component = unsafePerformEffect $ Hooks.reactComponent "Backdrop" \props -> Hooks.do
  canvas <- Hooks.useRef Nullable.null
  field <- Hooks.useRef Nothing
  Hooks.useEffectOnce do
    started <- startField canvas
    Hooks.writeRef field (Just started)
    pure do
      Hooks.writeRef field Nothing
      started.stop
  Hooks.useEffect props.ripples do
    when (props.ripples > 0) do
      current <- Hooks.readRef field
      for_ current \started -> started.ripple props.rippleOrigin
    pure (pure unit)
  pure $ DOM.div styleProps.root
    [ DOM.div { className: styleProps.layer.className, "aria-hidden": true }
        [ DOM.createBuiltinElement "canvas"
            { className: styleProps.canvas.className, ref: DOM.reactRef canvas } []
        ]
    , DOM.div styleProps.content props.content
    ]
