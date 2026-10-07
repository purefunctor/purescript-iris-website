module Website.Landing.Installation (installation) where

import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)
import Website.Components.CopyButton as CopyButton
import Website.Components.Tabs.Styles (tabStyles)

foreign import installationImpl ::
  ReactComponent
    { commandClassName :: String
    , copyButton :: String -> JSX
    , headerClassName :: String
    , iconClassName :: String
    , panelClassName :: String
    , promptClassName :: String
    , rootClassName :: String
    , sourceClassName :: String
    , sourceIconClassName :: String
    , systemClassName :: String
    , tabClassName :: String
    , tabListClassName :: String
    }

styles = StyleX.create
  { root:
      { display: "flex"
      , flexDirection: "column"
      , gap: 8
      , maxWidth: "100%"
      }
  , header:
      { alignItems: "center"
      , display: "flex"
      , flexWrap: "wrap"
      , gap: 8
      , justifyContent: "space-between"
      }
  -- Opens the selected platform's installation script.
  , source:
      { alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "var(--glass-fill)" }
      , borderRadius: 5
      , color: { default: "var(--text-tertiary)", ":hover": "var(--text-primary)" }
      , display: "inline-flex"
      , fontSize: 13
      , fontWeight: 500
      , gap: 6
      , lineHeight: 1
      -- Stays right-aligned when it wraps below the platform tabs on narrow screens.
      , marginInlineStart: "auto"
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , outline: { default: "revert", ":focus-visible": "none" }
      , paddingBlock: 7
      , paddingInline: 10
      , textDecoration: "none"
      , transitionDuration: "140ms"
      , transitionProperty: "background-color, color"
      , transitionTimingFunction: "var(--ease-out)"
      , whiteSpace: "nowrap"
      }
  -- Lucide icons render at 1.2em.
  , sourceIcon: { flexShrink: 0, fontSize: 11 }
  , system: { alignItems: "center", display: "inline-flex", gap: 6 }
  -- Simple Icons render at 1.2em; 11px keeps each logo near the label's cap height.
  , icon: { flexShrink: 0, fontSize: 11 }
  , panel:
      { "WebkitBackdropFilter": "blur(12px)"
      , alignItems: "center"
      , backdropFilter: "blur(12px)"
      , backgroundColor: "var(--glass-fill)"
      , borderColor: "var(--glass-border)"
      , borderRadius: 8
      , borderStyle: "solid"
      , borderWidth: 1
      , display: "flex"
      -- Fits the longer command (51 characters with its prompt) plus padding, gap, copy button
      -- and borders, so switching platforms keeps the copy button in place.
      , fontFamily: "var(--font-mono)"
      , fontSize: 14
      , gap: 12
      , maxWidth: "100%"
      , minHeight: 44
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , outline: { default: "revert", ":focus-visible": "none" }
      , paddingBlock: 3
      , paddingInlineStart: 16
      , paddingInlineEnd: 3
      , width: "calc(51ch + 69px)"
      }
  , command:
      { color: "var(--text-primary)"
      , flexGrow: 1
      , fontFamily: "var(--font-mono)"
      , fontSize: 14
      , lineHeight: 1.45
      , minWidth: 0
      , overflowWrap: "anywhere"
      }
  , prompt: { color: "var(--text-tertiary)", userSelect: "none" }
  }

styleProps = StyleX.recordProps styles

installation :: JSX
installation = element installationImpl
  { commandClassName: styleProps.command.className
  , copyButton: \text ->
      CopyButton.copyButton
        { label: "Copy installation command", size: CopyButton.Medium, text }
  , headerClassName: styleProps.header.className
  , iconClassName: styleProps.icon.className
  , panelClassName: styleProps.panel.className
  , promptClassName: styleProps.prompt.className
  , rootClassName: styleProps.root.className
  , sourceClassName: styleProps.source.className
  , sourceIconClassName: styleProps.sourceIcon.className
  , systemClassName: styleProps.system.className
  , tabClassName: (StyleX.props tabStyles.tab).className
  , tabListClassName: (StyleX.props tabStyles.tabList).className
  }
