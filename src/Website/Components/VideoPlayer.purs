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
foreign import seekTo :: Ref (Nullable Element) -> Number -> Effect Unit
foreign import toggleFullscreen ::
  { frame :: Ref (Nullable Element), video :: Ref (Nullable Element) } -> Effect Unit

foreign import observePlayer ::
  { bubble :: Ref (Nullable Element)
  , frame :: Ref (Nullable Element)
  , onEnded :: Effect Unit
  , onFullscreen :: Boolean -> Effect Unit
  , onTime :: Number -> Number -> Effect Unit
  , onToggle :: Effect Unit
  , onVisible :: Boolean -> Effect Unit
  , slider :: Ref (Nullable Element)
  , sources :: Array { src :: String, type :: String }
  , video :: Ref (Nullable Element)
  } -> Effect (Effect Unit)

type VideoPlayer =
  { label :: String
  , onEnded :: Effect Unit
  , onTime :: Number -> Effect Unit
  , playing :: Boolean
  , poster :: String
  , seek :: { request :: Int, time :: Number }
  , setPlaying :: (Boolean -> Boolean) -> Effect Unit
  , sources :: Array { src :: String, type :: String }
  }

styles = StyleX.create
  { frame:
      { aspectRatio: "16 / 9"
      , backgroundColor: "oklch(0% 0 0)"
      , borderColor: "var(--border-subtle)"
      , borderStyle: "solid"
      , borderWidth: { default: 1, ":fullscreen": 0 }
      , overflow: "hidden"
      , position: "relative"
      }
  , video:
      { cursor: "default"
      , display: "block"
      , height: "100%"
      , inset: 0
      , objectFit: "contain"
      , position: "absolute"
      , width: "100%"
      }
  , controls:
      { "WebkitBackdropFilter": "blur(30px)"
      , alignItems: "center"
      , backdropFilter: "blur(30px)"
      , backgroundColor: "var(--glass-fill-strong)"
      , borderColor: "var(--glass-border)"
      , borderStyle: "solid"
      , borderWidth: 1
      , display: "flex"
      , gap: 6
      , insetBlockEnd: 12
      , insetInline: 12
      , opacity: StyleX.conditionalValue 0
          [ When.ancestor ":hover" 1, When.ancestor ":has(:focus-visible)" 1 ]
      , padding: 3
      , position: "absolute"
      , transitionDuration: { default: "200ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
      , transitionProperty: "opacity"
      , transitionTimingFunction: "var(--ease-out)"
      }
  , controlsShown: { opacity: 1 }
  , mediaButton: { backgroundColor: { default: "transparent", ":hover": "var(--border-default)" } }
  , time:
      { color: "var(--text-secondary)"
      , flexShrink: 0
      , fontFamily: "var(--font-mono)"
      , fontSize: 12
      , fontVariantNumeric: "tabular-nums"
      , lineHeight: 1.3
      , paddingInlineEnd: 6
      }
  , slider:
      { "--seek-height": { default: "4px", "[data-seeking]": "6px" }
      , "--seek-thumb":
          { default: "0.75", ":hover": "1", ":focus-visible": "1", "[data-seeking]": "1.25" }
      , "--seek-preview": { default: "0", ":hover": "1" }
      , "--seek-bubble":
          { default: "0", ":hover": "1", ":focus-visible": "1", "[data-seeking]": "1" }
      , alignSelf: "stretch"
      , cursor: "default"
      , flexGrow: 1
      , marginInline: 6
      , minWidth: 48
      , outline: "none"
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , position: "relative"
      , touchAction: "none"
      }
  , track:
      { backgroundColor: "var(--border-default)"
      , height: "var(--seek-height)"
      , insetInline: 0
      , overflow: "hidden"
      , position: "absolute"
      , top: "50%"
      , transform: "translateY(-50%)"
      , transitionDuration: "140ms"
      , transitionProperty: "height"
      , transitionTimingFunction: "var(--ease-out)"
      }
  , fill: { inset: 0, position: "absolute", transformOrigin: "left" }
  , preview:
      { backgroundColor: "var(--border-strong)"
      , opacity: "var(--seek-preview)"
      , transform: "scaleX(var(--seek-pointer, 0))"
      }
  , progress: { backgroundColor: "var(--accent)", transform: "scaleX(var(--seek-progress, 0))" }
  , thumb:
      { backgroundColor: "var(--text-primary)"
      , borderRadius: 999
      , boxShadow: "0 0 0 3px oklch(from var(--accent) l c h / 35%)"
      , height: 12
      , left: "calc(var(--seek-progress, 0) * 100%)"
      , pointerEvents: "none"
      , position: "absolute"
      , top: "50%"
      , transform: "translate(-50%, -50%) scale(var(--seek-thumb))"
      , transitionDuration: "140ms"
      , transitionProperty: "transform"
      , transitionTimingFunction: "var(--ease-out)"
      , width: 12
      }
  , bubble:
      { "WebkitBackdropFilter": "blur(30px)"
      , backdropFilter: "blur(30px)"
      , backgroundColor: "var(--glass-fill-strong)"
      , borderColor: "var(--glass-border)"
      , borderStyle: "solid"
      , borderWidth: 1
      , bottom: "calc(100% + 10px)"
      , color: "var(--text-primary)"
      , fontFamily: "var(--font-mono)"
      , fontSize: 12
      , fontVariantNumeric: "tabular-nums"
      , left: "clamp(20px, calc(var(--seek-pointer, 0) * 100%), calc(100% - 20px))"
      , lineHeight: 1.3
      , opacity: "var(--seek-bubble)"
      , paddingBlock: 3
      , paddingInline: 6
      , pointerEvents: "none"
      , position: "absolute"
      , transform: "translateX(-50%)"
      , transitionDuration: "140ms"
      , transitionProperty: "opacity"
      , transitionTimingFunction: "var(--ease-out)"
      , whiteSpace: "nowrap"
      }
  }

styleProps = StyleX.recordProps styles

component :: ReactComponent VideoPlayer
component = unsafePerformEffect $ Hooks.reactComponent "VideoPlayer" \props -> Hooks.do
  frame <- Hooks.useRef Nullable.null
  video <- Hooks.useRef Nullable.null
  slider <- Hooks.useRef Nullable.null
  bubble <- Hooks.useRef Nullable.null
  time /\ setTime <- Hooks.useState' { current: 0.0, duration: 0.0 }
  fullscreen /\ setFullscreen <- Hooks.useState' false
  visible /\ setVisible <- Hooks.useState' false
  hoverable /\ setHoverable <- Hooks.useState' true
  let
    active = props.playing && visible
    toggle = props.setPlaying not
    controls = StyleX.props
      [ styles.controls, StyleX.conditional (not active || not hoverable) styles.controlsShown ]

  Hooks.useEffectOnce do
    reduced <- prefersReducedMotion
    when reduced $ props.setPlaying (const false)
    canHover >>= setHoverable
    observePlayer
      { bubble
      , frame
      , onEnded: props.onEnded
      , onFullscreen: setFullscreen
      , onTime: \current duration -> setTime { current, duration } *> props.onTime current
      , onToggle: toggle
      , onVisible: setVisible
      , slider
      , sources: props.sources
      , video
      }

  Hooks.useEffect props.seek.request do
    when (props.seek.request > 0) $ seekTo video props.seek.time
    pure (pure unit)

  Hooks.useEffect active do
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
        , "aria-label": props.label
        , onClick: handler_ toggle
        }
        []
    , DOM.div controls
        [ mediaButton (if active then "Pause" else "Play")
            (if active then Icon.pause else Icon.play) toggle
        , DOM.span styleProps.time (formatTime time.current <> " / " <> formatTime time.duration)
        , createBuiltinElement "div"
            { className: styleProps.slider.className
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
                [ DOM.div (StyleX.props [ styles.fill, styles.preview ]) []
                , DOM.div (StyleX.props [ styles.fill, styles.progress ]) []
                ]
            , DOM.div styleProps.thumb []
            , DOM.div
                { className: styleProps.bubble.className
                , ref: DOM.reactRef bubble
                , "aria-hidden": true
                }
                []
            ]
        , mediaButton (if fullscreen then "Exit full screen" else "Full screen")
            (if fullscreen then Icon.minimize else Icon.maximize)
            (toggleFullscreen { frame, video })
        ]
    ]

mediaButton :: String -> ReactComponent Icon.IconProps -> Effect Unit -> JSX
mediaButton label icon action = DOM.button
  { type: "button"
  , className:
      ( StyleX.props [ iconButtonStyles.button, iconButtonStyles.small, styles.mediaButton ]
      ).className
  , "aria-label": label
  , onClick: handler_ action
  }
  (element icon { "aria-hidden": true, focusable: false })
