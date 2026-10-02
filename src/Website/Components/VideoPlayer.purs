module Website.Components.VideoPlayer (VideoPlayer, component) where

import Prelude

import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Iris.StyleX as StyleX
import Iris.StyleX.When as When
import React.Basic (JSX, ReactComponent, Ref, element)
import React.Basic.Events (handler_)
import React.Basic.Hooks as Hooks
import Web.DOM.Element (Element)
import Website.Components.Icon as Icon
import Website.Components.IconButton.Styles (iconButtonStyles)
import Yoga.React.DOM as DOM
import Yoga.React.DOM.Internal (createBuiltinElement)

foreign import prefersReducedMotion :: Effect Boolean
foreign import canHover :: Effect Boolean
foreign import formatTime :: Number -> String
foreign import wholeSeconds :: Number -> Int
foreign import setPlayback :: Ref (Nullable Element) -> Boolean -> Effect Unit
foreign import toggleFullscreen ::
  { frame :: Ref (Nullable Element), video :: Ref (Nullable Element) } -> Effect Unit

foreign import observePlayer ::
  { frame :: Ref (Nullable Element)
  , onEnded :: Effect Unit
  , onFullscreen :: Boolean -> Effect Unit
  , onTime :: Number -> Number -> Effect Unit
  , onToggle :: Effect Unit
  , onVisible :: Boolean -> Effect Unit
  , progress :: Ref (Nullable Element)
  , slider :: Ref (Nullable Element)
  , video :: Ref (Nullable Element)
  } ->
  Effect (Effect Unit)

-- | A muted recording with custom controls. The caller owns the playing intent so that it can
-- | reflect it elsewhere; playback also waits until the player is on screen.
type VideoPlayer =
  { label :: String
  , onEnded :: Effect Unit
  , playing :: Boolean
  , poster :: String
  , setPlaying :: (Boolean -> Boolean) -> Effect Unit
  , src :: String
  }

styles = StyleX.create
  -- Recordings are letterboxed with plain black bars, on the page and in full screen.
  { frame:
      { aspectRatio: "16 / 9"
      , backgroundColor: "oklch(0% 0 0)"
      , borderColor: "var(--border-subtle)"
      , borderRadius: { default: 12, ":fullscreen": 0 }
      , borderStyle: "solid"
      , borderWidth: { default: 1, ":fullscreen": 0 }
      , overflow: "hidden"
      , position: "relative"
      }
  , video:
      { cursor: "var(--landing-interactive-cursor, pointer)"
      , display: "block"
      , height: "100%"
      , inset: 0
      , objectFit: "contain"
      , position: "absolute"
      , width: "100%"
      }
  -- Controls fade out during playback unless the player is hovered or holds focus.
  , controls:
      { opacity: StyleX.conditionalValue 0
          [ When.ancestor ":hover" 1, When.ancestor ":focus-within" 1 ]
      , transition: "opacity 200ms var(--ease-out)"
      , "@media (prefers-reduced-motion: reduce)": { transitionDuration: "0ms" }
      }
  , controlsShown: { opacity: 1 }
  , pill:
      { "WebkitBackdropFilter": "blur(30px)"
      , alignItems: "center"
      , backdropFilter: "blur(30px)"
      , backgroundColor: "var(--glass-fill-strong)"
      , borderColor: "var(--glass-border)"
      , borderRadius: 999
      , borderStyle: "solid"
      , borderWidth: 1
      , display: "inline-flex"
      , gap: 6
      , insetBlockEnd: 16
      , padding: 3
      , position: "absolute"
      }
  , playback: { insetInlineStart: 12, paddingInlineEnd: 12 }
  , fullscreen: { insetInlineEnd: 12 }
  , mediaButton:
      { backgroundColor: { default: "transparent", ":hover": "var(--border-default)" }
      , borderRadius: 999
      }
  , time:
      { color: "var(--text-secondary)"
      , fontFamily: "var(--font-mono)"
      , fontSize: 12
      , fontVariantNumeric: "tabular-nums"
      , lineHeight: 1.3
      }
  , slider:
      { "--seek-height": { default: "2px", ":hover": "4px", ":focus-visible": "4px" }
      , alignItems: "flex-end"
      , cursor: "var(--landing-interactive-cursor, pointer)"
      , display: "flex"
      , height: 14
      , insetBlockEnd: 0
      , insetInline: 0
      , outlineOffset: -2
      , position: "absolute"
      , touchAction: "none"
      }
  , track:
      { backgroundColor: "var(--border-default)"
      , height: "var(--seek-height)"
      , transition: "height 140ms var(--ease-out)"
      , width: "100%"
      }
  , progress:
      { backgroundColor: "var(--accent)"
      , height: "100%"
      , transform: "scaleX(0)"
      , transformOrigin: "left"
      }
  }

styleProps = StyleX.recordProps styles

component :: ReactComponent VideoPlayer
component = unsafePerformEffect $ Hooks.reactComponent "VideoPlayer" \props -> Hooks.do
  frame <- Hooks.useRef Nullable.null
  video <- Hooks.useRef Nullable.null
  slider <- Hooks.useRef Nullable.null
  progress <- Hooks.useRef Nullable.null
  time /\ setTime <- Hooks.useState' { current: 0.0, duration: 0.0 }
  fullscreen /\ setFullscreen <- Hooks.useState' false
  visible /\ setVisible <- Hooks.useState' false
  hoverable /\ setHoverable <- Hooks.useState' true
  let
    active = props.playing && visible
    toggle = props.setPlaying not
    controls extra =
      StyleX.props
        ( [ styles.controls ] <> extra <>
            [ StyleX.conditional (not active || not hoverable) styles.controlsShown ]
        )

  Hooks.useEffectOnce do
    reduced <- prefersReducedMotion
    when reduced $ props.setPlaying (const false)
    canHover >>= setHoverable
    observePlayer
      { frame
      , onEnded: props.onEnded
      , onFullscreen: setFullscreen
      , onTime: \current duration -> setTime { current, duration }
      , onToggle: toggle
      , onVisible: setVisible
      , progress
      , slider
      , video
      }

  Hooks.useEffect (props.src /\ active) do
    setPlayback video active
    pure (pure unit)

  pure $ DOM.div
    { className: (StyleX.props [ styles.frame, StyleX.defaultMarker ]).className
    , ref: DOM.reactRef frame
    }
    [ createBuiltinElement "video"
        { className: styleProps.video.className
        , ref: DOM.reactRef video
        , muted: true
        , playsInline: true
        , poster: props.poster
        , preload: "none"
        , src: props.src
        , "aria-label": props.label
        , onClick: handler_ toggle
        }
        []
    , DOM.div (controls [ styles.pill, styles.playback ])
        [ mediaButton (if active then "Pause" else "Play")
            (if active then Icon.pause else Icon.play)
            toggle
        , DOM.span styleProps.time
            (formatTime time.current <> " / " <> formatTime time.duration)
        ]
    , DOM.div (controls [ styles.pill, styles.fullscreen ])
        [ mediaButton (if fullscreen then "Exit full screen" else "Full screen")
            (if fullscreen then Icon.minimize else Icon.maximize)
            (toggleFullscreen { frame, video })
        ]
    , createBuiltinElement "div"
        { className: (controls [ styles.slider ]).className
        , ref: DOM.reactRef slider
        , role: "slider"
        , tabIndex: 0
        , "aria-label": "Recording position"
        , "aria-valuemin": 0
        , "aria-valuemax": wholeSeconds time.duration
        , "aria-valuenow": wholeSeconds time.current
        , "aria-valuetext": formatTime time.current <> " of " <> formatTime time.duration
        }
        [ DOM.div styleProps.track
            (DOM.div { className: styleProps.progress.className, ref: DOM.reactRef progress } [])
        ]
    ]

mediaButton :: String -> ReactComponent Icon.IconProps -> Effect Unit -> JSX
mediaButton label icon action =
  DOM.button
    { type: "button"
    , className:
        ( StyleX.props
            [ iconButtonStyles.button, iconButtonStyles.small, styles.mediaButton ]
        ).className
    , "aria-label": label
    , onClick: handler_ action
    }
    (element icon { "aria-hidden": true, focusable: false })
