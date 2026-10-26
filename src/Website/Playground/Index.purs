module Website.Playground.Index (component) where

import Prelude

import Data.Array (filter, length, null)
import Data.Maybe (Maybe(..), fromMaybe, isNothing)
import Data.Nullable (Nullable, toMaybe)
import Effect (Effect)
import Effect.Aff (Milliseconds(..), delay)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, Ref, element, fragment)
import React.Basic.Events (handler_)
import React.Basic.Hooks as Hooks
import React.Basic.Hooks.Aff (useAff)
import Web.DOM.Element (Element)
import Website.Breakpoints (breakpoints)
import Website.Components.ExternalLink (newTabLabel)
import Website.Components.Icon as Icon
import Website.Components.IconButton.Styles (iconButtonStyles)
import Website.Playground.Button.Styles (buttonStyles)
import Website.Playground.FileTabs (fileTabs)
import Website.Playground.FileTree (fileTree)
import Website.Playground.Loading (loading)
import Website.Playground.Packages (packagesPanel)
import Website.Playground.Templates (templateList)
import Website.Playground.Types (Actions, Line, Run, State, View)
import Yoga.React.DOM as DOM

foreign import playgroundImpl :: ReactComponent { theme :: Foreign, render :: View -> JSX }

foreign import sidebarImpl ::
  ReactComponent
    { id :: String
    , open :: Boolean
    , width :: Int
    , resize :: Int -> Effect Unit
    , close :: Effect Unit
    , className :: String
    , handleClassName :: String
    , children :: JSX
    }

-- | A status pill with a tooltip. An empty `href` makes it a focusable label instead of a link.
foreign import pillImpl ::
  ReactComponent
    { href :: String
    , label :: String
    , accessibleLabel :: String
    , tooltip :: String
    , className :: String
    , iconClassName :: String
    , tooltipClassName :: String
    }

foreign import panelImpl ::
  ReactComponent
    { id :: String
    , label :: String
    , open :: Boolean
    , width :: Int
    , height :: Int
    , resize :: { width :: Int, height :: Int } -> Effect Unit
    , close :: Effect Unit
    , className :: String
    , handleClassName :: String
    , children :: JSX
    }

-- | Shows the program's frame, which lives in `frames`, where this renders.
foreign import outputViewImpl ::
  ReactComponent { frames :: Ref (Nullable Element), className :: String }

-- | The program's messages, which follow new ones while scrolled to the bottom. An `overlay`
-- | console lies over the program's view below its `bar`, `height` pixels tall and at least ten
-- | messages, and collapses to the bar while not `open`.
foreign import consoleImpl ::
  ReactComponent
    { overlay :: Boolean
    , open :: Boolean
    , height :: Int
    , resize :: Int -> Effect Unit
    , close :: Effect Unit
    , className :: String
    , scrollerClassName :: String
    , handleClassName :: String
    , bar :: JSX
    , children :: JSX
    }

foreign import panelTabsImpl ::
  ReactComponent
    { selected :: String
    , select :: String -> Effect Unit
    , rootClassName :: String
    , barClassName :: String
    , tabListClassName :: String
    , settingsClassName :: String
    , tabClassName :: String
    , panelClassName :: String
    , switchedPanelClassName :: String
    , badgeClassName :: String
    , output :: JSX
    , outputAction :: JSX
    , outputBadge :: String
    , packages :: JSX
    , packagesBadge :: String
    }

styles = StyleX.create
  { page:
      { backgroundColor: "var(--bg-canvas)"
      , color: "var(--text-primary)"
      , display: "flex"
      , flexDirection: "column"
      , fontFamily: "var(--font-sans)"
      , fontSize: 14
      , height: "100dvh"
      }
  -- The playground's own header replaces the site navigation with the project's controls.
  , header:
      { alignItems: "center"
      , backgroundColor: "var(--granite-950)"
      , borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , display: "flex"
      , flexShrink: 0
      , gap: StyleX.conditionalValue 10 [ StyleX.conditionalCase breakpoints.upTo600 6 ]
      , height: "var(--nav-height)"
      , paddingInline: StyleX.conditionalValue 16 [ StyleX.conditionalCase breakpoints.upTo600 10 ]
      }
  -- Motion stays short and eases out, and reduced motion turns it off. The controls rise in once
  -- the playground is ready, as the workspace fades in below them.
  , controls:
      { alignItems: "center"
      , animationDuration: "260ms"
      , animationName: { default: rise, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: "var(--ease-out)"
      , display: "flex"
      , flexGrow: 1
      , gap: StyleX.conditionalValue 8 [ StyleX.conditionalCase breakpoints.upTo600 6 ]
      , minWidth: 0
      }
  , spacer: { flexGrow: 1 }
  -- The editor and its panel meet at a hard edge; the panel drops below the editor on narrow
  -- screens. The workspace is the container that sizes the panel's contents, and it clips the
  -- program's frame as the panel slides in from its edge.
  , workspace:
      { containerType: "size"
      , display: "flex"
      , flexDirection:
          StyleX.conditionalValue "row" [ StyleX.conditionalCase breakpoints.upTo960 "column" ]
      , flexGrow: 1
      , minHeight: 0
      , overflow: "hidden"
      , position: "relative"
      }
  -- Switching between Output and Packages fades the new panel in.
  , switched:
      { animationDuration: "160ms"
      , animationName: { default: fadeIn, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: "var(--ease-out)"
      }
  , revealed:
      { animationDuration: "320ms"
      , animationName: { default: fadeIn, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: "var(--ease-out)"
      }
  , upper:
      { display: "flex"
      , flexBasis: 0
      , flexGrow: 1
      , minHeight: 0
      , minWidth: 0
      , position: "relative"
      }
  -- The sidebar sits beside the editor, and over it on phones.
  , sidebar:
      { display: "flex"
      , flexShrink: 0
      , insetBlock: 0
      , insetInlineStart: 0
      -- Opening and closing grow and shrink the sidebar, so the editor follows its edge. Its
      -- sections keep their width at that edge, so they slide in rather than squeeze.
      , justifyContent: "flex-end"
      , position: StyleX.conditionalValue "relative"
          [ StyleX.conditionalCase breakpoints.upTo720 "absolute" ]
      , width: StyleX.conditionalValue "var(--sidebar-width)"
          [ StyleX.conditionalCase breakpoints.upTo720 "min(300px, 85vw)" ]
      , zIndex: 3
      , animationDuration: "200ms"
      , animationFillMode: "forwards"
      , animationName: { default: "none", "[data-entering]": widthIn, "[data-exiting]": widthOut }
      , animationTimingFunction: "var(--ease-out)"
      , overflow: "hidden"
      }
  -- Files take the sidebar's height above the templates.
  , sidebarSections:
      { borderInlineEndColor: StyleX.conditionalValue "var(--border-subtle)"
          [ StyleX.conditionalCase breakpoints.upTo720 "var(--border-strong)" ]
      , borderInlineEndStyle: "solid"
      , borderInlineEndWidth: 1
      , display: "flex"
      , flexDirection: "column"
      , flexShrink: 0
      , width: StyleX.conditionalValue "var(--sidebar-width)"
          [ StyleX.conditionalCase breakpoints.upTo720 "min(300px, 85vw)" ]
      }
  -- The sidebar's and the panel's edges, which drag to resize and close them below a minimum size.
  , handle:
      { backgroundColor:
          { default: "transparent"
          , ":hover": "var(--accent)"
          , ":focus-visible": "var(--focus-ring)"
          , "[data-dragging]": "var(--accent)"
          }
      , backgroundClip: "content-box"
      , outlineStyle: "none"
      , position: "absolute"
      , touchAction: "none"
      , transitionDelay: { default: "0ms", ":hover": "150ms" }
      , transitionDuration: "120ms"
      , transitionProperty: "background-color"
      , zIndex: 4
      }
  -- Phones open the sidebar over the editor instead, so they have no handle.
  , sidebarHandle:
      { cursor: "col-resize"
      , display:
          StyleX.conditionalValue "block" [ StyleX.conditionalCase breakpoints.upTo720 "none" ]
      , insetBlock: 0
      , paddingInline: 2
      , width: 6
      }
  -- The panel's handle follows its leading edge: its start beside the editor, its top below it.
  -- It reads the panel's capped size, so it stays on the edge at any window size.
  , panelHandle:
      { cursor: StyleX.conditionalValue "col-resize"
          [ StyleX.conditionalCase breakpoints.upTo960 "row-resize" ]
      , height: StyleX.conditionalValue "auto" [ StyleX.conditionalCase breakpoints.upTo960 "6px" ]
      , insetBlockEnd: StyleX.conditionalValue "0px"
          [ StyleX.conditionalCase breakpoints.upTo960
              "max(0px, calc(min(var(--panel-height), 70%) - 3px))"
          ]
      , insetBlockStart:
          StyleX.conditionalValue "0px" [ StyleX.conditionalCase breakpoints.upTo960 "auto" ]
      , insetInlineEnd: StyleX.conditionalValue "max(0px, calc(min(var(--panel-width), 70%) - 3px))"
          [ StyleX.conditionalCase breakpoints.upTo960 "0px" ]
      , insetInlineStart:
          StyleX.conditionalValue "auto" [ StyleX.conditionalCase breakpoints.upTo960 "0px" ]
      , paddingBlock: StyleX.conditionalValue 0 [ StyleX.conditionalCase breakpoints.upTo960 2 ]
      , paddingInline: StyleX.conditionalValue 2 [ StyleX.conditionalCase breakpoints.upTo960 0 ]
      , width: StyleX.conditionalValue "6px" [ StyleX.conditionalCase breakpoints.upTo960 "auto" ]
      }
  , editorColumn:
      { display: "flex", flexDirection: "column", flexGrow: 1, minHeight: 0, minWidth: 0 }
  , tabsRow:
      { backgroundColor: "var(--granite-950)"
      , borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , display: "flex"
      , flexShrink: 0
      , height: 36
      , minWidth: 0
      }
  , editor:
      { backgroundColor: "var(--granite-900)", flexGrow: 1, minHeight: 0, position: "relative" }
  , editorHost: { inset: 0, position: "absolute" }
  , noFile:
      { alignItems: "center"
      , color: "var(--text-tertiary)"
      , display: "flex"
      , fontSize: 14
      , inset: 0
      , justifyContent: "center"
      , margin: 0
      , position: "absolute"
      }
  , panel:
      -- The panel's size is its flex basis, which runs along the workspace beside the editor and
      -- down it below, so one animation opens the panel in both places.
      { flexBasis: StyleX.conditionalValue "min(var(--panel-width), 70%)"
          [ StyleX.conditionalCase breakpoints.upTo960 "min(var(--panel-height), 70%)" ]
      , flexShrink: 0
      , minHeight: 0
      , minWidth: 0
      , overflow: "hidden"
      , animationDuration: "220ms"
      , animationFillMode: "forwards"
      , animationName: { default: "none", "[data-entering]": basisIn, "[data-exiting]": basisOut }
      , animationTimingFunction: "var(--ease-out)"
      }
  -- The tabs keep the panel's open size at its leading edge, so they slide in rather than squeeze.
  -- The workspace's container units match the 70% cap of the panel's flex basis.
  , tabs:
      { backgroundColor: "var(--granite-950)"
      , borderInlineStartColor: "var(--border-subtle)"
      , borderInlineStartStyle:
          StyleX.conditionalValue "solid" [ StyleX.conditionalCase breakpoints.upTo960 "none" ]
      , borderInlineStartWidth: 1
      , borderBlockStartColor: "var(--border-subtle)"
      , borderBlockStartStyle:
          StyleX.conditionalValue "none" [ StyleX.conditionalCase breakpoints.upTo960 "solid" ]
      , borderBlockStartWidth: 1
      , display: "flex"
      , flexDirection: "column"
      , height: StyleX.conditionalValue "100%"
          [ StyleX.conditionalCase breakpoints.upTo960 "min(var(--panel-height), 70cqh)" ]
      , width: StyleX.conditionalValue "min(var(--panel-width), 70cqw)"
          [ StyleX.conditionalCase breakpoints.upTo960 "100%" ]
      }
  -- The panel's tabs scroll beside its settings, such as Clear, which stay put.
  , panelBar:
      { alignItems: "stretch"
      , borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , display: "flex"
      , flexShrink: 0
      , height: 36
      }
  -- panelTabsImpl marks the edges that hide tabs, and a fade there shows that the list scrolls.
  , tabList:
      { display: "flex"
      , flexGrow: 1
      , maskImage:
          { default: "none"
          , "[data-overflow=start]": "linear-gradient(to right, transparent, black 24px)"
          , "[data-overflow=end]": "linear-gradient(to left, transparent, black 24px)"
          , "[data-overflow=both]":
              "linear-gradient(to right, transparent, black 24px, black calc(100% - 24px), transparent)"
          }
      , minWidth: 0
      , overflowX: "auto"
      , overscrollBehaviorX: "contain"
      , scrollbarWidth: "none"
      }
  , panelSettings:
      { alignItems: "center"
      , borderInlineStartColor: "var(--border-subtle)"
      , borderInlineStartStyle: "solid"
      , borderInlineStartWidth: 1
      , display: "flex"
      , flexShrink: 0
      , gap: 6
      , paddingInline: 8
      }
  , tab:
      { alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-1)" }
      , boxShadow: { default: "none", "[data-selected]": "inset 0 -2px 0 var(--accent)" }
      , color:
          { default: "var(--text-tertiary)"
          , ":hover": "var(--text-primary)"
          , "[data-selected]": "var(--text-primary)"
          }
      , cursor: "default"
      , display: "flex"
      , fontSize: 13
      , fontWeight: 500
      , gap: 8
      , outlineColor: "var(--focus-ring)"
      , outlineOffset: -2
      , outlineStyle: { default: "none", "[data-focus-visible]": "solid" }
      , outlineWidth: 2
      , paddingInline: StyleX.conditionalValue 16 [ StyleX.conditionalCase breakpoints.upTo600 8 ]
      , transitionDuration: "140ms"
      , transitionProperty: "background-color, color"
      , transitionTimingFunction: "var(--ease-out)"
      }
  , badge:
      { backgroundColor: "var(--surface-3)"
      , borderRadius: 999
      , color: "var(--text-primary)"
      , fontSize: 11
      , fontWeight: 600
      , lineHeight: "16px"
      , minWidth: 16
      , paddingInline: 5
      , textAlign: "center"
      }
  , tabPanel:
      { display: "flex"
      , flexDirection: "column"
      , flexGrow: 1
      , minHeight: 0
      , outlineStyle: "none"
      , overflowY: "auto"
      }
  -- Status pills are sans-serif with flat, high-contrast fills.
  , status:
      { alignItems: "center"
      , borderRadius: 999
      , color: "var(--granite-950)"
      , display: "inline-flex"
      , fontSize: 12
      , fontWeight: 600
      , gap: 6
      , height: 26
      , maxWidth: 280
      , overflow: "hidden"
      , paddingInline: 11
      , textOverflow: "ellipsis"
      , whiteSpace: "nowrap"
      }
  , statusReady: { backgroundColor: "var(--green-400)" }
  -- The ready pill links to the release, so it brightens on hover like the other controls.
  -- The version and package set pills are raised like the Run key, from their own hues. The
  -- version links to its release, so it also brightens on hover and sinks while pressed.
  , statusLink:
      { backgroundColor: "var(--green-400)"
      , backgroundImage:
          { default:
              "linear-gradient(oklch(from var(--green-400) calc(l + 0.04) c h), oklch(from var(--green-400) calc(l - 0.04) c h))"
          , ":hover":
              "linear-gradient(oklch(from var(--green-400) calc(l + 0.07) c h), oklch(from var(--green-400) calc(l - 0.01) c h))"
          , ":active":
              "linear-gradient(oklch(from var(--green-400) calc(l - 0.04) c h), oklch(from var(--green-400) calc(l + 0.01) c h))"
          }
      , boxShadow:
          { default:
              "inset 0 1px 0 oklch(from var(--green-300) calc(l + 0.06) c h / 70%), inset 0 -1px 0 oklch(from var(--green-400) calc(l - 0.3) c h / 55%), 0 1px 2px oklch(0% 0 0 / 55%)"
          , ":active": "inset 0 1px 3px oklch(from var(--green-400) calc(l - 0.35) c h / 65%)"
          , ":focus-visible":
              "inset 0 1px 0 oklch(from var(--green-300) calc(l + 0.06) c h / 70%), inset 0 -1px 0 oklch(from var(--green-400) calc(l - 0.3) c h / 55%), var(--shadow-focus)"
          }
      , cursor: "default"
      , outline: { default: "revert", ":focus-visible": "none" }
      , textDecoration: "none"
      , textShadow: "0 1px 0 oklch(from var(--green-300) calc(l + 0.06) c h / 45%)"
      , transform: { default: "none", ":active": "translateY(1px)" }
      }
  , commit: { fontFamily: "var(--font-mono)" }
  -- Lucide icons render at 1.2em, so the arrow sits a little smaller than the pill's label.
  , externalIcon: { flexShrink: 0, fontSize: 10, marginInlineStart: -1 }
  , statusBusy:
      { backgroundColor: "var(--surface-2)"
      , boxShadow: "inset 0 0 0 1px var(--border-default)"
      , color: "var(--text-primary)"
      }
  , statusFailed: { backgroundColor: "var(--red-300)" }
  -- Round keys hold their width, so a crowded header cannot squeeze them into ovals.
  , iconOnly: { flexShrink: 0, paddingInline: 0, justifyContent: "center", width: 32 }
  -- While compiling, and running until Stop appears, the key stays held down rather than greying
  -- out, so a quick run reads as one press.
  , pressed:
      { backgroundColor: "var(--accent-press)"
      , boxShadow:
          "inset 0 1px 3px oklch(0% 0 0 / 45%), inset 0 0 0 oklch(0% 0 0 / 0%), 0 0 0 oklch(0% 0 0 / 0%)"
      , color: "var(--text-on-accent)"
      , textShadow: "0 1px 0 oklch(from var(--signal-200) l c h / 45%)"
      , transform: "translateY(1px)"
      }
  -- Stop, Share and Reset are the Run key without its accent.
  , neutral:
      { backgroundColor:
          { default: "var(--surface-3)"
          , ":hover": "oklch(from var(--surface-3) calc(l + 0.04) c h)"
          , ":active": "var(--surface-2)"
          }
      , color: "var(--text-primary)"
      }
  , icon: { display: "inline-flex", fontSize: 12 }
  , output:
      { display: "flex"
      , flexDirection: "column"
      , flexGrow: 1
      , fontFamily: "var(--font-mono)"
      , fontSize: 13
      , minHeight: 0
      , position: "relative"
      }
  , clear:
      { backgroundColor: { default: "transparent", ":hover": "var(--surface-2)" }
      , borderRadius: 999
      , borderStyle: "none"
      , color: { default: "var(--text-tertiary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , fontFamily: "var(--font-sans)"
      , fontSize: 12
      , height: 24
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , outline: { default: "revert", ":focus-visible": "none" }
      , paddingInline: 10
      }
  -- The console reads like a browser's: one row per message, split by hairlines, with warnings
  -- and errors tinted in their own hues and marked by an icon. consoleImpl's minimum height is its
  -- bar and ten of these rows, so keep its arithmetic in step with their sizes.
  , console: { display: "flex", flexDirection: "column", flexGrow: 1, minHeight: 0 }
  , consoleScroller: { flexGrow: 1, minHeight: 0, overflowY: "auto" }
  -- A program that renders fills the panel, and its console lies over the view's lower edge.
  , view: { flexGrow: 1, minHeight: 0 }
  , overlayConsole:
      { backgroundColor: "var(--granite-950)"
      , borderBlockStartColor: "var(--border-default)"
      , borderBlockStartStyle: "solid"
      , borderBlockStartWidth: 1
      , boxShadow: "0 -10px 24px oklch(0% 0 0 / 35%)"
      , flexGrow: 0
      , insetBlockEnd: 0
      , insetInline: 0
      , maxHeight: "100%"
      , overflow: "hidden"
      , position: "absolute"
      , zIndex: 5
      }
  , consoleHandle: { cursor: "row-resize", height: 6, insetInline: 0, paddingBlock: 2, zIndex: 6 }
  -- The bar collapses and brings up the console, and counts its messages, warnings and errors.
  , consoleBar:
      { alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-1)" }
      , borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , borderBlockStartStyle: "none"
      , borderInlineStyle: "none"
      , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , display: "flex"
      , flexShrink: 0
      , fontFamily: "var(--font-sans)"
      , fontSize: 12
      , fontWeight: 500
      , gap: 8
      , height: 28
      , outlineColor: "var(--focus-ring)"
      , outlineOffset: -2
      , outlineStyle: { default: "none", ":focus-visible": "solid" }
      , outlineWidth: 2
      , paddingInline: 8
      , textAlign: "start"
      , transitionDuration: "140ms"
      , transitionProperty: "background-color, color"
      , transitionTimingFunction: "var(--ease-out)"
      , width: "100%"
      }
  , chevron:
      { display: "inline-flex"
      , fontSize: 12
      , transitionDuration: { default: "160ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
      , transitionProperty: "transform"
      , transitionTimingFunction: "var(--ease-out)"
      }
  , collapsedChevron: { transform: "rotate(180deg)" }
  , counts: { alignItems: "center", display: "flex", gap: 10, marginInlineStart: "auto" }
  , count:
      { alignItems: "center", display: "inline-flex", fontVariantNumeric: "tabular-nums", gap: 4 }
  , warningCount: { color: "var(--yellow-300)" }
  , errorCount: { color: "var(--red-300)" }
  , line:
      { borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , display: "flex"
      , gap: 8
      , lineHeight: "18px"
      , paddingBlock: 2
      , paddingInlineEnd: 12
      , paddingInlineStart: 8
      }
  -- The icon centers on the message's first line, which is as tall as the icon's box.
  , lineIcon:
      { alignItems: "center"
      , display: "inline-flex"
      , flexShrink: 0
      , fontSize: 11
      , height: 18
      , justifyContent: "center"
      , width: 14
      }
  , lineText: { minWidth: 0, overflowWrap: "anywhere", whiteSpace: "pre-wrap" }
  , logLine: { color: "var(--text-secondary)" }
  , infoLine: { color: "var(--text-tertiary)" }
  -- A tinted row also tints the separator above it, as browsers do.
  , warningLine:
      { backgroundColor: "oklch(from var(--yellow-300) l c h / 8%)"
      , borderBlockEndColor: "oklch(from var(--yellow-300) l c h / 22%)"
      , boxShadow: "0 -1px 0 oklch(from var(--yellow-300) l c h / 22%)"
      , color: "var(--yellow-300)"
      }
  , errorLine:
      { backgroundColor: "oklch(from var(--red-300) l c h / 9%)"
      , borderBlockEndColor: "oklch(from var(--red-300) l c h / 24%)"
      , boxShadow: "0 -1px 0 oklch(from var(--red-300) l c h / 24%)"
      , color: "var(--red-300)"
      }
  , empty:
      { color: "var(--text-tertiary)"
      , fontFamily: "var(--font-sans)"
      , fontSize: 13
      , lineHeight: 1.6
      , margin: 0
      , paddingBlock: 12
      , paddingInline: 16
      }
  , packageSet:
      { backgroundColor: "var(--blue-300)"
      , backgroundImage:
          "linear-gradient(oklch(from var(--blue-300) calc(l + 0.04) c h), oklch(from var(--blue-300) calc(l - 0.04) c h))"
      , boxShadow:
          { default:
              "inset 0 1px 0 oklch(from var(--blue-300) calc(l + 0.1) calc(c - 0.04) h / 70%), inset 0 -1px 0 oklch(from var(--blue-300) calc(l - 0.32) c h / 55%), 0 1px 2px oklch(0% 0 0 / 55%)"
          , ":focus-visible":
              "inset 0 1px 0 oklch(from var(--blue-300) calc(l + 0.1) calc(c - 0.04) h / 70%), inset 0 -1px 0 oklch(from var(--blue-300) calc(l - 0.32) c h / 55%), var(--shadow-focus)"
          }
      , outline: { default: "revert", ":focus-visible": "none" }
      , textShadow: "0 1px 0 oklch(from var(--blue-300) calc(l + 0.1) calc(c - 0.04) h / 45%)"
      , display: StyleX.conditionalValue "inline-flex"
          [ StyleX.conditionalCase breakpoints.upTo720 "none" ]
      }
  -- Run and Stop, and Share and Copied, share one grid cell, so each button keeps its widest
  -- label's width. Compiling, and running until Stop appears, keep the Run label and turn its
  -- icon into a spinner.
  , labels: { display: "grid" }
  , label:
      { alignItems: "center"
      , display: "inline-flex"
      , gap: 6
      , gridArea: "1 / 1"
      , justifyContent: "center"
      , transitionDuration: { default: "160ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
      , transitionProperty: "opacity, visibility"
      , transitionTimingFunction: "var(--ease-out)"
      }
  -- Labels crossfade, and a hidden one stays in the grid to hold the button's width.
  , inactiveLabel: { opacity: 0, visibility: "hidden" }
  , popped:
      { animationDuration: "240ms"
      , animationName: { default: pop, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: "var(--ease-out)"
      }
  -- The panel toggle's icon shows where the panel sits: beside the editor, or below it.
  , besidePanel:
      { display: StyleX.conditionalValue "inline-flex"
          [ StyleX.conditionalCase breakpoints.upTo960 "none" ]
      }
  , belowPanel:
      { display: StyleX.conditionalValue "none"
          [ StyleX.conditionalCase breakpoints.upTo960 "inline-flex" ]
      }
  , shareLabels:
      { display:
          StyleX.conditionalValue "grid" [ StyleX.conditionalCase breakpoints.upTo600 "none" ]
      }
  -- Without its label, Share is a round key like Reset beside it.
  , shareKey:
      { flexShrink: 0
      , justifyContent: "center"
      , paddingInline: StyleX.conditionalValue 16 [ StyleX.conditionalCase breakpoints.upTo600 0 ]
      , width: StyleX.conditionalValue "auto" [ StyleX.conditionalCase breakpoints.upTo600 "32px" ]
      }
  , spinner:
      { animationDuration: "900ms"
      , animationIterationCount: "infinite"
      , animationName: { default: spin, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: "linear"
      , display: "inline-flex"
      , fontSize: 12
      }
  , frames: { height: 0, overflow: "hidden", position: "absolute", width: 0 }
  }

styleProps = StyleX.recordProps styles

spin = StyleX.keyframes { from: { transform: "rotate(0deg)" }, to: { transform: "rotate(360deg)" } }

fadeIn = StyleX.keyframes { from: { opacity: 0 }, to: { opacity: 1 } }

rise = StyleX.keyframes
  { from: { opacity: 0, transform: "translateY(4px)" }, to: { opacity: 1, transform: "none" } }

pop = StyleX.keyframes
  { from: { transform: "scale(0.5)" }
  , "60%": { transform: "scale(1.15)" }
  , to: { transform: "none" }
  }

-- Without a `to` frame, these open to the element's own size.
widthIn = StyleX.keyframes { from: { width: 0 } }

widthOut = StyleX.keyframes { to: { width: 0 } }

basisIn = StyleX.keyframes { from: { flexBasis: 0 } }

basisOut = StyleX.keyframes { to: { flexBasis: 0 } }

component :: ReactComponent { theme :: Foreign }
component = unsafePerformEffect $ Hooks.reactComponent "Playground" \{ theme } ->
  pure $ element playgroundImpl { theme, render: playground }

playground :: View -> JSX
playground { state, actions, editor, frames } = DOM.div styleProps.page
  [ DOM.header styleProps.header [ if ready then controls else mempty ]
  -- The children keep their positions in every phase, so that React keeps the editor host that
  -- the controller fills once loading finishes.
  , DOM.main (StyleX.props [ styles.workspace, StyleX.conditional ready styles.revealed ])
      [ DOM.div styleProps.upper
          [ if ready then sidebar else mempty
          , DOM.div styleProps.editorColumn
              [ if ready then tabs else mempty
              , DOM.div styleProps.editor
                  [ DOM.div { className: styleProps.editorHost.className, ref: DOM.reactRef editor }
                      []
                  , if ready && noFile
                    then DOM.p styleProps.noFile "Open a file from Files."
                    else mempty
                  ]
              ]
          ]
      , if ready then panel else mempty
      , if ready then mempty else loading state actions.retry
      , DOM.div { className: styleProps.frames.className, ref: DOM.reactRef frames } []
      ]
  ]
  where
  ready = state.phase == "ready"
  noFile = isNothing (toMaybe state.active) && isNothing (toMaybe state.viewing)

  controls = DOM.div styleProps.controls
    [ DOM.button
        { className: (StyleX.props [ buttonStyles.action, styles.iconOnly ]).className
        , onClick: handler_ actions.toggleSidebar
        , title: if state.sidebar then "Hide files" else "Show files"
        , type: "button"
        , "aria-controls": "playground-sidebar"
        , "aria-expanded": state.sidebar
        , "aria-label": "Files"
        }
        (DOM.span styleProps.icon (icon Icon.panelLeft))
    , DOM.div styleProps.spacer []
    , status state
    , case toMaybe state.packages.packageSet of
        Just packageSet -> element pillImpl
          { href: ""
          , label: packageSet
          , accessibleLabel: "Package set " <> packageSet
          , tooltip: "Package set"
          , className: (StyleX.props [ styles.status, styles.packageSet ]).className
          , iconClassName: ""
          , tooltipClassName: (StyleX.props iconButtonStyles.tooltip).className
          }
        Nothing -> mempty
    , iconAction "Reset to the example" Icon.rotateCcw actions.reset
    , DOM.button
        { className:
            ( StyleX.props
                [ buttonStyles.action, buttonStyles.raised, styles.neutral, styles.shareKey ]
            ).className
        , onClick: handler_ actions.share
        , title: "Copy a link to this project"
        , type: "button"
        , "aria-label": if state.shared then "Copied" else "Share"
        }
        [ DOM.span (StyleX.props [ styles.icon, StyleX.conditional state.shared styles.popped ])
            (icon (if state.shared then Icon.check else Icon.share))
        , DOM.span (StyleX.props [ styles.labels, styles.shareLabels ])
            [ stackedLabel "Share" (not state.shared), stackedLabel "Copied" state.shared ]
        ]
    , element runButton
        { status: state.run.status
        , ready: state.server.status == "ready"
        , run: actions.run
        , stop: actions.stop
        }
    , DOM.button
        { className: (StyleX.props [ buttonStyles.action, styles.iconOnly ]).className
        , onClick: handler_ actions.togglePanel
        , title: if state.panel then "Hide output" else "Show output"
        , type: "button"
        , "aria-controls": "playground-panel"
        , "aria-expanded": state.panel
        , "aria-label": "Output and packages"
        }
        [ DOM.span (StyleX.props [ styles.icon, styles.besidePanel ]) (icon Icon.panelRight)
        , DOM.span (StyleX.props [ styles.icon, styles.belowPanel ]) (icon Icon.panelBottom)
        ]
    ]

  sidebar = element sidebarImpl
    { id: "playground-sidebar"
    , open: state.sidebar
    , width: state.sidebarWidth
    , resize: actions.resizeSidebar
    , close: actions.closeSidebar
    , className: styleProps.sidebar.className
    , handleClassName: (StyleX.props [ styles.handle, styles.sidebarHandle ]).className
    , children: DOM.div styleProps.sidebarSections
        [ fileTree { files: state.files, active: state.active, viewing: state.viewing, actions }
        , templateList { templates: state.templates, actions }
        ]
    }

  tabs = DOM.div styleProps.tabsRow
    [ fileTabs
        { files: state.files
        , open: state.open
        , active: state.active
        , viewing: state.viewing
        , actions
        }
    ]

  panel = element panelImpl
    { id: "playground-panel"
    , label: "Output and packages"
    , open: state.panel
    , width: state.panelWidth
    , height: state.panelHeight
    , resize: actions.resizePanel
    , close: actions.closePanel
    , className: styleProps.panel.className
    , handleClassName: (StyleX.props [ styles.handle, styles.panelHandle ]).className
    , children: element panelTabsImpl
        { selected: state.panelTab
        , select: actions.selectPanelTab
        , rootClassName: styleProps.tabs.className
        , barClassName: styleProps.panelBar.className
        , tabListClassName: styleProps.tabList.className
        , settingsClassName: styleProps.panelSettings.className
        , tabClassName: styleProps.tab.className
        , panelClassName: styleProps.tabPanel.className
        , switchedPanelClassName: (StyleX.props [ styles.tabPanel, styles.switched ]).className
        , badgeClassName: styleProps.badge.className
        , output: output state actions frames
        , outputAction: clearButton state.run actions.clearOutput
        , outputBadge: ""
        , packages: packagesPanel
            { packages: state.packages
            , busy: state.server.status == "starting" || state.server.status == "restarting"
            , activate: actions.activatePackage
            , deactivate: actions.deactivatePackage
            }
        , packagesBadge: if state.packages.active == 0 then "" else show state.packages.active
        }
    }

icon :: ReactComponent Icon.IconProps -> JSX
icon component' = element component' { "aria-hidden": true, focusable: false }

iconAction :: String -> ReactComponent Icon.IconProps -> Effect Unit -> JSX
iconAction label icon' onPress = DOM.button
  { className:
      ( StyleX.props [ buttonStyles.action, buttonStyles.raised, styles.neutral, styles.iconOnly ]
      ).className
  , onClick: handler_ onPress
  , title: label
  , type: "button"
  , "aria-label": label
  }
  (DOM.span styleProps.icon (icon icon'))

-- | The Run key. Stop takes its place only once a program has run for half a second, so that
-- | quick programs do not flash Stop; until then the key stays Run and keeps compiling's spinner.
runButton ::
  ReactComponent { status :: String, ready :: Boolean, run :: Effect Unit, stop :: Effect Unit }
runButton = unsafePerformEffect $ Hooks.reactComponent "RunButton" \{ status, ready, run, stop } ->
  Hooks.do
    let
      running = status == "running"
    started <- useAff running (if running then delay (Milliseconds 500.0) $> true else pure false)
    let
      stoppable = running && started == Just true
      busy = status == "compiling" || running && not stoppable
      disabled = busy || not ready && not stoppable
    pure $ DOM.button
      { className:
          ( StyleX.props
              [ buttonStyles.action
              , buttonStyles.raised
              , if stoppable
                then styles.neutral
                else if busy
                then styles.pressed
                else if disabled
                then buttonStyles.raised
                else buttonStyles.accent
              ]
          ).className
      , disabled
      , onClick: handler_ (if stoppable then stop else run)
      , type: "button"
      , "aria-label":
          if stoppable
          then "Stop"
          else if running
          then "Running"
          else if busy
          then "Compiling"
          else "Run"
      }
      ( DOM.span styleProps.labels
          [ label "Run" (not stoppable)
              [ if busy
                then DOM.span styleProps.spinner (icon Icon.loaderCircle)
                else DOM.span styleProps.icon (icon Icon.play)
              ]
          , label "Stop" stoppable [ DOM.span styleProps.icon (icon Icon.square) ]
          ]
      )
  where
  label text current icons = DOM.span
    { className:
        ( StyleX.props [ styles.label, StyleX.conditional (not current) styles.inactiveLabel ]
        ).className
    , "aria-hidden": not current
    }
    (icons <> [ DOM.text text ])

-- | One of several labels that share a grid cell, so that a button keeps its widest label's
-- | width as the label changes.
stackedLabel :: String -> Boolean -> JSX
stackedLabel text current = DOM.span
  { className:
      ( StyleX.props [ styles.label, StyleX.conditional (not current) styles.inactiveLabel ]
      ).className
  , "aria-hidden": not current
  }
  text

status :: State -> JSX
status state = case server.status, toMaybe server.kind, toMaybe server.version of
  "failed", _, _ -> pill "Language server stopped" styles.statusFailed
  -- A restart keeps the same release, so a known version stays in place.
  "restarting", _, Nothing -> pill "Restarting the language server" styles.statusBusy
  "starting", _, _ -> pill "Starting the language server" styles.statusBusy
  _, Just "mock", _ -> mempty
  _, _, Just version -> element pillImpl
    { href: "https://github.com/purefunctor/purescript-iris/releases/tag/" <> version
    , label: version
    , accessibleLabel: "Iris " <> version <> " release" <> newTabLabel
    , tooltip: fromMaybe version (toMaybe server.revision)
    , className: (StyleX.props [ styles.status, styles.statusLink ]).className
    , iconClassName: styleProps.externalIcon.className
    , tooltipClassName: (StyleX.props [ iconButtonStyles.tooltip, styles.commit ]).className
    }
  _, _, Nothing -> pill "Iris language server" styles.statusReady
  where
  server = state.server
  pill label tone = DOM.span
    { className: (StyleX.props [ styles.status, tone ]).className
    , role: "status"
    , title: fromMaybe label (toMaybe server.message)
    }
    label

-- | What `main` printed, below what it rendered, if it did. The Run key already shows whether the
-- | project is compiling or running, and errors and stops arrive as lines, so the output has no
-- | status of its own.
output :: State -> Actions -> Ref (Nullable Element) -> JSX
output state actions frames = DOM.div styleProps.output
  if run.view
  then
    [ element outputViewImpl { frames, className: styleProps.view.className }
    , if null run.lines then mempty else console true
    ]
  else
    [ case run.status, null run.lines of
        "idle", true -> DOM.p styleProps.empty "Run the project to see what main prints or renders."
        "done", true -> DOM.p styleProps.empty "main finished without printing anything."
        _, _ -> console false
    ]
  where
  run = state.run
  console overlay = element consoleImpl
    { overlay
    , open: state.console
    , height: state.consoleHeight
    , resize: actions.resizeConsole
    , close: actions.closeConsole
    , className:
        ( StyleX.props [ styles.console, StyleX.conditional overlay styles.overlayConsole ]
        ).className
    , scrollerClassName: styleProps.consoleScroller.className
    , handleClassName: (StyleX.props [ styles.handle, styles.consoleHandle ]).className
    , bar: consoleBar state.console run.lines actions.toggleConsole
    , children: fragment (map outputLine run.lines)
    }

consoleBar :: Boolean -> Array Line -> Effect Unit -> JSX
consoleBar open lines toggle = DOM.button
  { className: styleProps.consoleBar.className
  , onClick: handler_ toggle
  , title: if open then "Collapse the console" else "Bring up the console"
  , type: "button"
  , "aria-controls": "playground-console"
  , "aria-expanded": open
  , "aria-label": "Console, "
      <> plural (length lines) "message"
      <> label warnings "warning"
      <> label errors "error"
  }
  [ DOM.span
      (StyleX.props [ styles.chevron, StyleX.conditional (not open) styles.collapsedChevron ])
      (icon Icon.chevronDown)
  , DOM.text "Console"
  , DOM.span styleProps.counts
      [ counter warnings styles.warningCount Icon.triangleAlert
      , counter errors styles.errorCount Icon.circleX
      , DOM.span styleProps.badge (show (length lines))
      ]
  ]
  where
  warnings = count "warning"
  errors = count "error"
  count kind = length (filter (\line -> line.kind == kind) lines)
  counter n tone icon'
    | n == 0 = mempty
    | otherwise = DOM.span (StyleX.props [ styles.count, tone ])
      [ DOM.span styleProps.icon (icon icon'), DOM.text (show n) ]
  label n word = if n == 0 then "" else ", " <> plural n word
  plural n word = show n <> " " <> word <> if n == 1 then "" else "s"

clearButton :: Run -> Effect Unit -> JSX
clearButton run clear
  | null run.lines = mempty
  | otherwise =
    DOM.button { className: styleProps.clear.className, onClick: handler_ clear, type: "button" }
      "Clear"

outputLine :: Line -> JSX
outputLine line = DOM.div (StyleX.props [ styles.line, tone ])
  [ DOM.span styleProps.lineIcon marker, DOM.span styleProps.lineText line.text ]
  where
  { tone, marker } = case line.kind of
    "error" -> { tone: styles.errorLine, marker: icon Icon.circleX }
    "warning" -> { tone: styles.warningLine, marker: icon Icon.triangleAlert }
    "info" -> { tone: styles.infoLine, marker: mempty }
    _ -> { tone: styles.logLine, marker: mempty }
