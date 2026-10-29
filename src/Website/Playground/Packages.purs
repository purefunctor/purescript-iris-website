module Website.Playground.Packages (packagesPanel) where

import Prelude

import Data.Array (filter, length, null, sortBy)
import Data.Maybe (isJust)
import Data.Ord (comparing)
import Data.Set (Set)
import Data.Set as Set
import Data.String (Pattern(..), contains, localeCompare, stripPrefix, toLower, trim)
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent)
import React.Basic.Events (EventFn, SyntheticEvent, handler, handler_, unsafeEventFn)
import React.Basic.Hooks as Hooks
import Unsafe.Coerce (unsafeCoerce)
import Website.Jotai as Jotai
import Website.Playground.Types (Available, Packages)
import Yoga.React.DOM as DOM
import Yoga.React.DOM.Attributes.Target (targetBlank)

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

queryAtom :: Jotai.Atom String
queryAtom = unsafePerformEffect (Jotai.atom "")

showAllAtom :: Jotai.Atom Boolean
showAllAtom = unsafePerformEffect (Jotai.atom false)

rowsKeptAfterDeactivatingAtom :: Jotai.Atom (Set String)
rowsKeptAfterDeactivatingAtom = unsafePerformEffect (Jotai.atom Set.empty)

packagesPanel ::
  ReactComponent
    { packages :: Packages
    , busy :: Boolean
    , activate :: String -> Effect Unit
    , deactivate :: String -> Effect Unit
    }
packagesPanel = unsafePerformEffect $ Hooks.reactComponent "PlaygroundPackages" \props -> Hooks.do
  query /\ setQuery <- Jotai.useAtom queryAtom
  showAll /\ setShowAll <- Jotai.useAtom showAllAtom
  rowsKept /\ setRowsKept <- Jotai.useAtom rowsKeptAfterDeactivatingAtom
  let
    found :: Array Available
    found = search query props.packages.available

    isActive :: Available -> Boolean
    isActive entry =
      entry.status == "active" || entry.status == "dependency" || Set.member entry.name rowsKept

    matches :: Array Available
    matches = if showAll then found else filter isActive found

    showOnly :: Boolean -> Effect Unit
    showOnly all = do
      setShowAll (const all)
      setRowsKept (const Set.empty)

    deactivateKeepingShownRows :: String -> Effect Unit
    deactivateKeepingShownRows name = do
      unless showAll do
        setRowsKept (_ `Set.union` Set.fromFoldable (map _.name matches))
      props.deactivate name
  pure $ DOM.div styleProps.root
    [ DOM.div styleProps.search
        [ DOM.input
            { "aria-label": "Search packages"
            , className: styleProps.input.className
            , onChange: handler targetValue \value -> setQuery (const value)
            , placeholder: "Search "
                <> show (if showAll then length props.packages.available else props.packages.active)
                <> " packages"
            , spellCheck: false
            , type: "search"
            , value: query
            }
        , DOM.div
            { "aria-label": "Show packages"
            , className: styleProps.filters.className
            , role: "group"
            }
            [ DOM.span
                { "aria-hidden": true
                , className:
                    ( StyleX.props [ styles.thumb, StyleX.conditional showAll styles.thumbEnd ]
                    ).className
                }
                ([] :: Array JSX)
            , filterButton (not showAll) (showOnly false) ("Active " <> show props.packages.active)
            , filterButton showAll (showOnly true)
                ("All " <> show (length props.packages.available))
            ]
        ]
    , DOM.ul { "aria-label": "Packages", className: styleProps.list.className }
        ( map
            ( packageRow
                { busy: props.busy
                , activate: props.activate
                , deactivate: deactivateKeepingShownRows
                }
            )
            matches
        )
    , if null matches
      then DOM.p styleProps.note
        if null found
        then "No package in this package set matches."
        else "No active package matches; show all packages to activate one."
      else mempty
    ]

search :: String -> Array Available -> Array Available
search query available =
  let
    needle :: String
    needle = toLower (trim query)

    startsWith :: Available -> Boolean
    startsWith entry = isJust (stripPrefix (Pattern needle) entry.name)

    byPrefixThenName :: Available -> Available -> Ordering
    byPrefixThenName a b = comparing (not <<< startsWith) a b <> localeCompare a.name b.name
  in
    if needle == ""
    then available
    else sortBy byPrefixThenName (filter (\entry -> contains (Pattern needle) entry.name) available)

filterButton :: Boolean -> Effect Unit -> String -> JSX
filterButton pressed onPress label = DOM.button
  { "aria-pressed": pressed
  , className: styleProps.filter.className
  , onClick: handler_ onPress
  , type: "button"
  }
  label

type PackageActions =
  { busy :: Boolean, activate :: String -> Effect Unit, deactivate :: String -> Effect Unit }

packageRow :: PackageActions -> Available -> JSX
packageRow actions entry = DOM.li { className: styleProps.row.className, key: entry.name }
  [ DOM.a
      { className: styleProps.name.className
      , href: "https://pursuit.purescript.org/packages/purescript-"
          <> entry.name
          <> "/"
          <> entry.version
      , rel: "noreferrer"
      , target: targetBlank
      , title: entry.name
      }
      entry.name
  , DOM.span styleProps.version entry.version
  , packageToggle actions entry
  ]

targetValue :: EventFn SyntheticEvent String
targetValue = unsafeEventFn \event ->
  (unsafeCoerce event :: { target :: { value :: String } }).target.value

packageToggle :: PackageActions -> Available -> JSX
packageToggle { busy, activate, deactivate } entry =
  let
    locked :: Boolean
    locked = entry.status == "dependency"

    on :: Boolean
    on = locked || entry.status == "active"
  in
    DOM.button
      { "aria-checked": on
      , "aria-label": entry.name
      , className: (StyleX.props [ styles.track, StyleX.conditional on styles.trackOn ]).className
      , disabled: busy || locked
      , onClick: handler_ ((if on then deactivate else activate) entry.name)
      , role: "switch"
      , title: if locked then "Required by " <> entry.requiredBy else ""
      , type: "button"
      }
      ( DOM.span
          { className: (StyleX.props [ styles.knob, StyleX.conditional on styles.knobOn ]).className
          }
          ( DOM.createBuiltinElement "svg"
              { "aria-hidden": true, className: styleProps.icon.className, viewBox: "0 0 12 12" }
              [ DOM.createBuiltinElement "path"
                  { className:
                      (StyleX.props [ styles.mark, StyleX.conditional on styles.markOn ]).className
                  , d: if on then "M2.5 6.5 L5 9 M5 9 L9.5 3" else "M3 3 L9 9 M9 3 L3 9"
                  }
                  ([] :: Array JSX)
              ]
          )
      )
