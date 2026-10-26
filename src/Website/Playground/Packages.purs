module Website.Playground.Packages (packagesPanel) where

import Prelude

import Effect (Effect)
import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)
import Website.Playground.Types (Packages)

foreign import packagesImpl ::
  ReactComponent
    { packages :: Packages
    , busy :: Boolean
    , activate :: String -> Effect Unit
    , deactivate :: String -> Effect Unit
    , rootClassName :: String
    , searchClassName :: String
    , inputClassName :: String
    , filtersClassName :: String
    , filterClassName :: String
    , thumbClassName :: String
    , thumbEndClassName :: String
    , noteClassName :: String
    , listClassName :: String
    , rowClassName :: String
    , nameClassName :: String
    , versionClassName :: String
    , toggleClassNames ::
        { track :: String
        , trackOn :: String
        , knob :: String
        , knobOn :: String
        , icon :: String
        , mark :: String
        , markOn :: String
        }
    }

styles = StyleX.create
  { root: { display: "flex", flexDirection: "column", flexGrow: 1, minHeight: 0 }
  , search:
      { borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , display: "flex"
      , flexShrink: 0
      , gap: 8
      , padding: 12
      }
  , input:
      { backgroundColor: "var(--granite-950)"
      , borderColor: { default: "var(--border-default)", ":focus": "var(--accent)" }
      , borderRadius: 999
      , borderStyle: "solid"
      , borderWidth: 1
      , color: "var(--text-primary)"
      , fontFamily: "var(--font-sans)"
      , fontSize: 14
      , height: 36
      , outlineStyle: "none"
      , minWidth: 0
      , paddingInline: 16
      , flexGrow: 1
      }
  , filters:
      { backgroundColor: "var(--granite-950)"
      , borderRadius: 999
      , boxShadow: "inset 0 1px 3px oklch(0% 0 0 / 55%), inset 0 -1px 0 oklch(100% 0 0 / 6%)"
      , display: "grid"
      , flexShrink: 0
      , gridTemplateColumns: "1fr 1fr"
      , padding: 3
      , position: "relative"
      }
  , thumb:
      { backgroundColor: "var(--surface-2)"
      , backgroundImage: "linear-gradient(oklch(100% 0 0 / 12%), oklch(0% 0 0 / 10%))"
      , borderRadius: 999
      , boxShadow:
          "inset 0 1px 0 oklch(100% 0 0 / 22%), inset 0 -1px 0 oklch(0% 0 0 / 35%), 0 1px 2px oklch(0% 0 0 / 55%)"
      , insetBlock: 3
      , insetInlineStart: 3
      , position: "absolute"
      , transform: "none"
      , transitionDuration: { default: "180ms", "@media (prefers-reduced-motion: reduce)": "0s" }
      , transitionProperty: "transform"
      , transitionTimingFunction: "var(--ease-out)"
      , width: "calc(50% - 3px)"
      }
  , thumbEnd: { transform: "translateX(100%)" }
  , filter:
      { backgroundColor: "transparent"
      , borderRadius: 999
      , borderStyle: "none"
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , color:
          { default: "var(--text-tertiary)"
          , ":hover": "var(--text-primary)"
          , "[aria-pressed=true]": "var(--text-primary)"
          }
      , cursor: "default"
      , fontFamily: "var(--font-sans)"
      , fontSize: 12
      , fontVariantNumeric: "tabular-nums"
      , fontWeight: 600
      , height: 28
      , outline: { default: "revert", ":focus-visible": "none" }
      , paddingInline: 10
      , position: "relative"
      , textShadow: { default: "none", "[aria-pressed=true]": "0 -1px 0 oklch(0% 0 0 / 35%)" }
      , transitionDuration: "140ms"
      , transitionProperty: "color"
      , transitionTimingFunction: "var(--ease-out)"
      , whiteSpace: "nowrap"
      }
  , note:
      { borderBlockStartColor: "var(--border-subtle)"
      , borderBlockStartStyle: "solid"
      , borderBlockStartWidth: 1
      , color: "var(--text-tertiary)"
      , flexShrink: 0
      , fontSize: 13
      , lineHeight: 1.5
      , margin: 0
      , paddingBlock: 8
      , paddingInline: 16
      }
  , list:
      { flexGrow: 1
      , listStyle: "none"
      , margin: 0
      , minHeight: 0
      , overflowY: "auto"
      , paddingBlock: 8
      , paddingInline: 0
      }
  , row:
      { alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-1)" }
      , display: "flex"
      , gap: 10
      , minHeight: 36
      , paddingInline: 16
      }
  , name:
      { color: { default: "var(--text-primary)", ":hover": "var(--accent-text)" }
      , flexGrow: 1
      , fontFamily: "var(--font-mono)"
      , fontSize: 13
      , minWidth: 0
      , overflow: "hidden"
      , textDecorationLine: { default: "none", ":hover": "underline" }
      , textOverflow: "ellipsis"
      , whiteSpace: "nowrap"
      }
  , version: { color: "var(--text-tertiary)", fontFamily: "var(--font-mono)", fontSize: 12 }
  , track:
      { backgroundColor: "var(--granite-950)"
      , borderRadius: 999
      , borderStyle: "none"
      , boxShadow:
          { default: "inset 0 1px 3px oklch(0% 0 0 / 55%), inset 0 -1px 0 oklch(100% 0 0 / 6%)"
          , ":focus-visible":
              "inset 0 1px 3px oklch(0% 0 0 / 55%), inset 0 -1px 0 oklch(100% 0 0 / 6%), var(--shadow-focus)"
          }
      , cursor: "default"
      , flexShrink: 0
      , height: 24
      , opacity: { default: 1, ":disabled": 0.45 }
      , outline: { default: "revert", ":focus-visible": "none" }
      , padding: 0
      , position: "relative"
      , transitionDuration: { default: "180ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
      , transitionProperty: "background-color, opacity"
      , transitionTimingFunction: "var(--ease-out)"
      , width: 44
      }
  , trackOn: { backgroundColor: "var(--surface-3)" }
  , knob:
      { alignItems: "center"
      , backgroundColor: "var(--surface-2)"
      , backgroundImage: "linear-gradient(oklch(100% 0 0 / 12%), oklch(0% 0 0 / 10%))"
      , borderRadius: 999
      , boxShadow:
          "inset 0 1px 0 oklch(100% 0 0 / 22%), inset 0 -1px 0 oklch(0% 0 0 / 35%), 0 1px 2px oklch(0% 0 0 / 55%)"
      , color: "var(--text-tertiary)"
      , display: "flex"
      , height: 18
      , insetBlockStart: 3
      , insetInlineStart: 3
      , justifyContent: "center"
      , position: "absolute"
      , transform: "none"
      , transitionDuration: { default: "180ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
      , transitionProperty: "color, transform"
      , transitionTimingFunction: "var(--ease-out)"
      , width: 18
      }
  , knobOn: { color: "var(--text-primary)", transform: "translateX(20px)" }
  , icon: { display: "block", height: 10, overflow: "visible", width: 10 }
  , mark:
      { d: "path(\"M3 3 L9 9 M9 3 L3 9\")"
      , fill: "none"
      , stroke: "currentColor"
      , strokeLinecap: "round"
      , strokeLinejoin: "round"
      , strokeWidth: 2
      , transitionDuration: { default: "180ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
      , transitionProperty: "d"
      , transitionTimingFunction: "var(--ease-out)"
      }
  , markOn: { d: "path(\"M2.5 6.5 L5 9 M5 9 L9.5 3\")" }
  }

styleProps = StyleX.recordProps styles

packagesPanel ::
  { packages :: Packages
  , busy :: Boolean
  , activate :: String -> Effect Unit
  , deactivate :: String -> Effect Unit
  } -> JSX
packagesPanel { packages, busy, activate, deactivate } = element packagesImpl
  { packages
  , busy
  , activate
  , deactivate
  , rootClassName: styleProps.root.className
  , searchClassName: styleProps.search.className
  , inputClassName: styleProps.input.className
  , filtersClassName: styleProps.filters.className
  , filterClassName: styleProps.filter.className
  , thumbClassName: styleProps.thumb.className
  , thumbEndClassName: (StyleX.props [ styles.thumb, styles.thumbEnd ]).className
  , noteClassName: styleProps.note.className
  , listClassName: styleProps.list.className
  , rowClassName: styleProps.row.className
  , nameClassName: styleProps.name.className
  , versionClassName: styleProps.version.className
  , toggleClassNames:
      { track: styleProps.track.className
      , trackOn: (StyleX.props [ styles.track, styles.trackOn ]).className
      , knob: styleProps.knob.className
      , knobOn: (StyleX.props [ styles.knob, styles.knobOn ]).className
      , icon: styleProps.icon.className
      , mark: styleProps.mark.className
      , markOn: (StyleX.props [ styles.mark, styles.markOn ]).className
      }
  }
