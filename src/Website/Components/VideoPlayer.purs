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
foreign import after :: Int -> Effect Unit -> Effect (Effect Unit)
foreign import toggleFullscreen ::
  { frame :: Ref (Nullable Element), video :: Ref (Nullable Element) } -> Effect Unit

foreign import observePlayer ::
  { bubble :: Ref (Nullable Element)
  , frame :: Ref (Nullable Element)
  , onEnded :: Effect Unit
  , onFullscreen :: Boolean -> Effect Unit
  , onLoaded :: Effect Unit
  , onTime :: Number -> Number -> Effect Unit
  , onToggle :: Effect Unit
  , onVisible :: Boolean -> Effect Unit
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

-- | How long the outgoing recording blurs before its source is replaced; matches `blurred`.
blurOut :: Int
blurOut = 160

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
      , transitionDuration: "260ms"
      , transitionProperty: "opacity"
      , transitionTimingFunction: "var(--ease-out)"
      , width: "100%"
      }
  , videoBlurred: { opacity: 0.5, transitionDuration: "160ms" }
  -- Switching recordings blurs the outgoing frame, then the incoming recording unblurs once its
  -- first frame has loaded. A backdrop filter extends the frame's edges rather than fading them
  -- into the letterbox as a filter on the video would.
  , blur:
      { "WebkitBackdropFilter": "blur(0px)"
      , backdropFilter: "blur(0px)"
      , inset: 0
      , pointerEvents: "none"
      , position: "absolute"
      , transitionDuration: "260ms"
      , transitionProperty: "backdrop-filter, -webkit-backdrop-filter"
      , transitionTimingFunction: "var(--ease-out)"
      }
  , blurred:
      { "WebkitBackdropFilter": "blur(12px)"
      , backdropFilter: "blur(12px)"
      , transitionDuration: "160ms"
      }
  -- Controls fade out during playback unless the player is hovered or holds keyboard focus;
  -- focus left behind by a mouse click does not keep them visible.
  , controls:
      { "WebkitBackdropFilter": "blur(30px)"
      , alignItems: "center"
      , backdropFilter: "blur(30px)"
      , backgroundColor: "var(--glass-fill-strong)"
      , borderColor: "var(--glass-border)"
      , borderRadius: 999
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
  , mediaButton:
      { backgroundColor: { default: "transparent", ":hover": "var(--border-default)" }
      , borderRadius: 999
      }
  , time:
      { color: "var(--text-secondary)"
      , flexShrink: 0
      , fontFamily: "var(--font-mono)"
      , fontSize: 12
      , fontVariantNumeric: "tabular-nums"
      , lineHeight: 1.3
      , paddingInlineEnd: 6
      }
  -- The script sets --seek-progress and --seek-pointer (0 to 1) and data-seeking while dragging.
  , slider:
      { "--seek-height": { default: "4px", "[data-seeking]": "6px" }
      , "--seek-thumb":
          { default: "0.75", ":hover": "1", ":focus-visible": "1", "[data-seeking]": "1.25" }
      , "--seek-preview": { default: "0", ":hover": "1" }
      , "--seek-bubble":
          { default: "0", ":hover": "1", ":focus-visible": "1", "[data-seeking]": "1" }
      , alignSelf: "stretch"
      , borderRadius: 999
      , cursor: "var(--landing-interactive-cursor, pointer)"
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
      , borderRadius: 999
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
  , progress:
      { backgroundColor: "var(--accent)"
      , transform: "scaleX(var(--seek-progress, 0))"
      }
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
      , borderRadius: 5
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
  -- The source on the element trails props.src while the outgoing recording blurs.
  shown /\ setShown <- Hooks.useState' props.src
  blurred /\ setBlurred <- Hooks.useState' false
  let
    active = props.playing && visible
    current = shown == props.src
    toggle = props.setPlaying not
    controls =
      StyleX.props
        [ styles.controls
        , StyleX.conditional (not active || not hoverable) styles.controlsShown
        ]

  Hooks.useEffectOnce do
    reduced <- prefersReducedMotion
    when reduced $ props.setPlaying (const false)
    canHover >>= setHoverable
    observePlayer
      { bubble
      , frame
      , onEnded: props.onEnded
      , onFullscreen: setFullscreen
      , onLoaded: setBlurred false
      , onTime: \current duration -> setTime { current, duration }
      , onToggle: toggle
      , onVisible: setVisible
      , slider
      , video
      }

  -- Returning to the shown recording mid-blur, or reducing motion, skips the transition.
  Hooks.useEffect props.src do
    reduced <- prefersReducedMotion
    if current || reduced then do
      setBlurred false
      setShown props.src
      pure (pure unit)
    else do
      setBlurred true
      after blurOut (setShown props.src)

  -- The outgoing recording holds its frame while it blurs. An incoming recording that will not
  -- load until played unblurs straight away.
  Hooks.useEffect (shown /\ props.src /\ active) do
    setPlayback video (active && current)
    when (current && not active) (setBlurred false)
    pure (pure unit)

  pure $ DOM.div
    { className: (StyleX.props [ styles.frame, StyleX.defaultMarker ]).className
    , ref: DOM.reactRef frame
    }
    [ createBuiltinElement "video"
        { className:
            (StyleX.props [ styles.video, StyleX.conditional blurred styles.videoBlurred ]).className
        , ref: DOM.reactRef video
        , muted: true
        , playsInline: true
        , poster: props.poster
        , preload: "none"
        , src: shown
        , "aria-label": props.label
        , onClick: handler_ toggle
        }
        []
    , DOM.div (StyleX.props [ styles.blur, StyleX.conditional blurred styles.blurred ]) []
    , DOM.div controls
        [ mediaButton (if active then "Pause" else "Play")
            (if active then Icon.pause else Icon.play)
            toggle
        , DOM.span styleProps.time
            (formatTime time.current <> " / " <> formatTime time.duration)
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
