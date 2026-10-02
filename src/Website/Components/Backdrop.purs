module Website.Components.Backdrop (component) where

import Prelude

import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, Ref)
import React.Basic.Hooks as Hooks
import Web.DOM.Element (Element)
import Yoga.React.DOM as DOM

foreign import startField ::
  Ref (Nullable Element) -> Effect (Effect Unit)

styles = StyleX.create
  { root:
      { backgroundColor: "var(--bg-canvas)"
      , isolation: "isolate"
      , overflow: "hidden"
      , position: "relative"
      }
  , layer: { inset: 0, pointerEvents: "none", position: "absolute", zIndex: 0 }
  , canvas: { height: "100%", inset: 0, position: "absolute", width: "100%" }
  , fade:
      { backgroundImage: "linear-gradient(transparent, var(--bg-canvas))"
      , blockSize: "22%"
      , insetBlockEnd: 0
      , insetInline: 0
      , position: "absolute"
      }
  , grain:
      { backgroundImage: "var(--texture-grain)"
      , backgroundSize: 240
      , inset: 0
      , mixBlendMode: "overlay"
      , opacity: 0.09
      , position: "absolute"
      }
  , content: { position: "relative", zIndex: 1 }
  }

styleProps = StyleX.recordProps styles

-- | The brand's animated dot field, with a clearing in the top-left corner behind the copy.
component :: ReactComponent { content :: Array JSX }
component = unsafePerformEffect $ Hooks.reactComponent "Backdrop" \{ content } -> Hooks.do
  canvas <- Hooks.useRef Nullable.null
  Hooks.useEffectOnce $ startField canvas
  pure $ DOM.div styleProps.root
    [ DOM.div { className: styleProps.layer.className, "aria-hidden": true }
        [ DOM.createBuiltinElement "canvas"
            { className: styleProps.canvas.className, ref: DOM.reactRef canvas }
            []
        , DOM.div styleProps.fade []
        , DOM.div styleProps.grain []
        ]
    , DOM.div styleProps.content content
    ]
