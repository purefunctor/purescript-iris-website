module Website.Landing.Index (component) where

import Prelude

import Data.Foldable (for_)
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Iris.StyleX as StyleX
import React.Basic (ReactComponent, Ref, element)
import React.Basic.Hooks as Hooks
import Web.DOM.Element (Element)
import Web.DOM.Element as Element
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLHtmlElement as HTMLHtmlElement
import Web.HTML.Navigator as Navigator
import Web.HTML.Window as Window
import Website.Components.SiteNav (siteNav)
import Website.Landing.Demos as Demos
import Website.Landing.Features (features)
import Website.Landing.Footer (footer)
import Website.Landing.Hero (hero)
import Website.Landing.Places (places)
import Yoga.React.DOM as DOM

foreign import revealInstall :: Ref (Nullable Element) -> Effect Unit -> Effect Unit

styles = StyleX.create
  { page:
      { backgroundColor: "var(--bg-canvas)"
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
  Hooks.useEffectOnce configurePlatformStyles
  pure $ DOM.div (StyleX.props styles.page)
    [ siteNav { onInstall: revealInstall install (setRipples (_ + 1)) }
    , DOM.main {}
        [ hero { install, ripples }
        , places
        , features
        , element Demos.component {}
        ]
    , footer
    ]

configurePlatformStyles :: Effect (Effect Unit)
configurePlatformStyles = do
  browserWindow <- window
  platform <- Window.navigator browserWindow >>= Navigator.platform
  when (isMacOS platform) do
    document <- Window.document browserWindow
    documentElement <- HTMLDocument.documentElement document
    for_ documentElement \html ->
      Element.setAttribute "data-landing-macos" "" (HTMLHtmlElement.toElement html)
  pure (pure unit)

isMacOS :: String -> Boolean
isMacOS = case _ of
  "MacIntel" -> true
  "MacPPC" -> true
  "Mac68K" -> true
  "macOS" -> true
  _ -> false
