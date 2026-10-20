module Website.Playground.Packages (packagesPanel) where

import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)
import Website.Playground.Types (Packages)

foreign import packagesImpl ::
  ReactComponent
    { packages :: Packages
    , rootClassName :: String
    , searchClassName :: String
    , inputClassName :: String
    , noteClassName :: String
    , listClassName :: String
    , rowClassName :: String
    , nameClassName :: String
    , versionClassName :: String
    }

styles = StyleX.create
  -- The list scrolls on its own, so the search and the count stay in place.
  { root: { display: "flex", flexDirection: "column", flexGrow: 1, minHeight: 0 }
  , search:
      { borderBlockEndColor: "var(--border-subtle)"
      , borderBlockEndStyle: "solid"
      , borderBlockEndWidth: 1
      , flexShrink: 0
      , padding: 12
      }
  , input:
      { backgroundColor: "var(--granite-950)"
      , borderColor: { default: "var(--border-default)", ":focus": "var(--accent)" }
      , borderRadius: 6
      , borderStyle: "solid"
      , borderWidth: 1
      , color: "var(--text-primary)"
      , fontFamily: "var(--font-sans)"
      , fontSize: 14
      , height: 36
      , outlineStyle: "none"
      , paddingInline: 12
      , width: "100%"
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
  -- Package names are text-styled links, so they keep the pointing-hand cursor.
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
  }

styleProps = StyleX.recordProps styles

-- | The package panel: a search over the package set, which the project can import in full.
packagesPanel :: { packages :: Packages } -> JSX
packagesPanel { packages } = element packagesImpl
  { packages
  , rootClassName: styleProps.root.className
  , searchClassName: styleProps.search.className
  , inputClassName: styleProps.input.className
  , noteClassName: styleProps.note.className
  , listClassName: styleProps.list.className
  , rowClassName: styleProps.row.className
  , nameClassName: styleProps.name.className
  , versionClassName: styleProps.version.className
  }
