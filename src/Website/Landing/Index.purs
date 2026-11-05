module Website.Landing.Index (component) where

import Prelude

import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Iris.StyleX as StyleX
import React.Basic (ReactComponent, Ref, element)
import React.Basic.Hooks as Hooks
import Web.DOM.Element (Element)
import Website.Components.SiteNav (siteNav)
import Website.Landing.Benchmarks (benchmarks)
import Website.Landing.Closing (closing)
import Website.Landing.Demos as Demos
import Website.Landing.Footer (footer)
import Website.Landing.Hero (hero)
import Website.Landing.Output (output)
import Website.Landing.Specs as Specs
import Website.Landing.Toolchain (toolchain)
import Yoga.React.DOM as DOM

foreign import revealInstall :: Ref (Nullable Element) -> Effect Unit -> Effect Unit
foreign import enableCopyEditing :: Effect (Effect Unit)

styles = StyleX.create
  { page:
      { backgroundColor: "var(--bg-canvas)"
      , backgroundImage: "var(--canvas-texture)"
      , color: "var(--text-primary)"
      , fontFamily: "var(--font-sans)"
      , fontSize: 15
      , lineHeight: 1.65
      , minHeight: "100vh"
      }
  }

component :: ReactComponent {}
component = unsafePerformEffect $ Hooks.reactComponent "LandingPage" \_ -> Hooks.do
  install <- Hooks.useRef Nullable.null
  ripples /\ setRipples <- Hooks.useState 0
  Hooks.useEffectOnce enableCopyEditing
  pure $ DOM.div (StyleX.props styles.page)
    [ siteNav { onInstall: revealInstall install (setRipples (_ + 1)) }
    , DOM.main {}
        [ hero { install, ripples }
        , element Specs.component {}
        , toolchain
        , output
        , benchmarks
        , element Demos.component {}
        , closing
        ]
    , footer
    ]
