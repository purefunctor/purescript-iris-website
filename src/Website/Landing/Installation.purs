module Website.Landing.Installation (installation) where

import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)
import Website.Components.CopyButton as CopyButton

foreign import installationImpl ::
  ReactComponent
    { commandClassName :: String
    , copyButton :: String -> JSX
    , iconClassName :: String
    , panelClassName :: String
    , promptClassName :: String
    , rootClassName :: String
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
  , tabList: { display: "flex", gap: 2 }
  , tab:
      { alignItems: "center"
      , borderRadius: 5
      , color:
          { default: "var(--text-tertiary)"
          , ":hover": "var(--text-primary)"
          , "[data-selected]": "var(--text-primary)"
          }
      , backgroundColor:
          { default: "transparent"
          , ":hover": "var(--glass-fill)"
          , "[data-selected]": "var(--glass-fill-strong)"
          }
      , cursor: "var(--landing-interactive-cursor, pointer)"
      , display: "inline-flex"
      , fontSize: 13
      , gap: 5
      , fontWeight: 500
      , lineHeight: 1
      , padding: "7px 10px"
      , transition: "background-color 140ms var(--ease-out), color 140ms var(--ease-out)"
      , whiteSpace: "nowrap"
      , ":focus-visible": { boxShadow: "var(--shadow-focus)", outline: "none" }
      }
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
      , paddingBlock: 3
      , paddingInline: "16px 3px"
      , width: "calc(51ch + 69px)"
      , ":focus-visible": { boxShadow: "var(--shadow-focus)", outline: "none" }
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
  , iconClassName: styleProps.icon.className
  , panelClassName: styleProps.panel.className
  , promptClassName: styleProps.prompt.className
  , rootClassName: styleProps.root.className
  , systemClassName: styleProps.system.className
  , tabClassName: styleProps.tab.className
  , tabListClassName: styleProps.tabList.className
  }
