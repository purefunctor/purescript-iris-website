module Website.Components.Documentation (Page(..), Section, documentation) where

import Prelude

import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element, fragment)
import Website.Breakpoints (breakpoints)
import Website.Components.Icon as Icon
import Website.Components.NavigationLink as NavigationLink
import Website.Components.SiteNav as SiteNav
import Yoga.React.DOM as DOM

data Page = GettingStarted | Installation | LanguageServer | Formatting | ModuleMetadata

derive instance Eq Page

pages :: Array Page
pages = [ GettingStarted, Installation, LanguageServer, Formatting, ModuleMetadata ]

pageHref :: Page -> String
pageHref = case _ of
  GettingStarted -> "/docs/getting-started/"
  Installation -> "/docs/installation/"
  LanguageServer -> "/docs/language-server/"
  Formatting -> "/docs/formatting/"
  ModuleMetadata -> "/docs/module-metadata/"

pageTitle :: Page -> String
pageTitle = case _ of
  GettingStarted -> "Getting started"
  Installation -> "Installation"
  LanguageServer -> "Language server"
  Formatting -> "Formatting"
  ModuleMetadata -> "Module metadata"

type Section = { id :: String, title :: String, body :: Array JSX }

type SectionLink = { id :: String, title :: String }

type Links =
  { listClassName :: String
  , className :: String
  , currentClassName :: String
  , canvasClassName :: String
  , contentClassName :: String
  }

foreign import sectionNavigationImpl ::
  ReactComponent { sections :: Array SectionLink, links :: Links }

foreign import navigationBarImpl ::
  ReactComponent
    { sections :: Array SectionLink
    , links :: Links
    , pages :: JSX
    , classes ::
        { bar :: String
        , pagesTrigger :: String
        , pagesIcon :: String
        , sectionsTrigger :: String
        , label :: String
        , current :: String
        , chevron :: String
        , popover :: String
        , pagesPopover :: String
        , dialog :: String
        }
    }

fadeIn = StyleX.keyframes { from: { opacity: 0 }, to: { opacity: 1 } }
fadeOut = StyleX.keyframes { from: { opacity: 1 }, to: { opacity: 0 } }

styles = StyleX.create
  { page: { fontSize: 16, lineHeight: 1.75, color: "var(--text-secondary)" }
  , headerLinks:
      { display: "flex"
      , alignSelf: "stretch"
      , flexShrink: 0
      , marginInlineStart: "auto"
      , marginInlineEnd: -16
      }
  , layout:
      { display: "grid"
      , gridTemplateColumns:
          StyleX.conditionalValue "var(--rail-width) minmax(0, 1fr) var(--rail-width)"
            [ StyleX.conditionalCase breakpoints.above720To1160 "var(--rail-width) minmax(0, 1fr)"
            , StyleX.conditionalCase breakpoints.upTo720 "minmax(0, 1fr)"
            ]
      , alignItems: "start"
      }
  , rail:
      { display:
          StyleX.conditionalValue "block" [ StyleX.conditionalCase breakpoints.upTo720 "none" ]
      , position: "sticky"
      , top: "var(--nav-height)"
      , height: "calc(100dvh - var(--nav-height))"
      , overflowY: "auto"
      , backgroundColor: "var(--granite-900)"
      , paddingInline: "calc(var(--gutter) - 12px)"
      , paddingBlockStart: 64
      , paddingBlockEnd: 32
      }
  , sectionRail:
      { display:
          StyleX.conditionalValue "block" [ StyleX.conditionalCase breakpoints.upTo1160 "none" ]
      }
  , column: { minWidth: 0 }
  , bar:
      { display:
          StyleX.conditionalValue "none" [ StyleX.conditionalCase breakpoints.upTo1160 "flex" ]
      , position: "sticky"
      , top: "var(--nav-height)"
      , zIndex: 15
      , height: 48
      , backgroundColor: "var(--granite-900)"
      }
  , trigger:
      { display: "flex"
      , alignItems: "center"
      , gap: 12
      , height: "100%"
      , paddingInline: 16
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-1)" }
      , color: "var(--text-primary)"
      , cursor: "default"
      , fontSize: 14
      , textAlign: "start"
      , outlineColor: "var(--focus-ring)"
      , outlineOffset: -2
      }
  , pagesTrigger:
      { display:
          StyleX.conditionalValue "none" [ StyleX.conditionalCase breakpoints.upTo720 "flex" ]
      , flexShrink: 0
      , gap: 8
      , paddingInlineStart: "clamp(24px, 4.5vw, 72px)"
      , borderInlineEndColor: "var(--border-subtle)"
      , borderInlineEndStyle: "solid"
      , borderInlineEndWidth: 1
      }
  , sectionsTrigger:
      { flexGrow: 1
      , minWidth: 0
      , paddingInlineStart: StyleX.conditionalValue "clamp(24px, 4.5vw, 72px)"
          [ StyleX.conditionalCase breakpoints.upTo720 "16px" ]
      , paddingInlineEnd: "clamp(24px, 4.5vw, 72px)"
      }
  , barLabel: { flexShrink: 0, fontWeight: 600 }
  , barCurrent:
      { minWidth: 0
      , overflow: "hidden"
      , textOverflow: "ellipsis"
      , whiteSpace: "nowrap"
      , color: "var(--text-tertiary)"
      }
  , barIcon: { flexShrink: 0, fontSize: 16, color: "var(--text-tertiary)" }
  , chevron: { marginInlineStart: "auto" }
  , popover:
      { width: "var(--trigger-width)"
      , overflowY: "auto"
      , backgroundColor: "var(--granite-900)"
      , boxShadow: "0 28px 40px -20px oklch(0% 0 0 / 70%)"
      , outline: "none"
      , animationName: { default: "none", "[data-entering]": fadeIn, "[data-exiting]": fadeOut }
      , animationDuration: { default: "140ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
      }
  , pagesPopover: { height: "calc(100dvh - var(--nav-height) - 48px)" }
  , popoverDialog:
      { paddingInline: "calc(clamp(24px, 4.5vw, 72px) - 12px)"
      , paddingBlockStart: 8
      , paddingBlockEnd: 16
      , outline: "none"
      }
  , label:
      { fontSize: 13
      , fontWeight: 600
      , color: "var(--text-primary)"
      , paddingInline: 12
      , marginBlockEnd: 10
      }
  , links: { display: "flex", flexDirection: "column", gap: 2, marginBlockEnd: 32 }
  , link:
      { position: "relative"
      , isolation: "isolate"
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-1)" }
      , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , display: "flex"
      , alignItems: "center"
      , justifyContent: "space-between"
      , gap: 10
      , paddingBlock: 7
      , paddingInline: 12
      , fontSize: 14
      , lineHeight: 1.5
      , textDecoration: "none"
      , outlineColor: "var(--focus-ring)"
      }
  , current:
      { color: "var(--text-primary)"
      , textDecorationLine: "underline"
      , textDecorationColor: "var(--accent)"
      , textDecorationThickness: 1
      , textUnderlineOffset: 6
      }
  , resourceIcon:
      { display: "inline-flex", flexShrink: 0, fontSize: 11, color: "var(--text-tertiary)" }
  , article:
      { marginInline: "auto"
      , maxWidth: "calc(72ch + 2 * clamp(24px, 4.5vw, 72px))"
      , paddingInline: "clamp(24px, 4.5vw, 72px)"
      , fontSize: "clamp(16px, 0.25vw + 12.4px, 18px)"
      , paddingBlockStart:
          StyleX.conditionalValue 56 [ StyleX.conditionalCase breakpoints.upTo720 32 ]
      , paddingBlockEnd: 80
      }
  , title:
      { fontSize: "clamp(38px, 4vw, 54px)"
      , color: "var(--text-primary)"
      , fontWeight: 650
      , letterSpacing: "-0.045em"
      , lineHeight: 1.1
      , marginBlockEnd: 20
      }
  , intro: { display: "flex", flexDirection: "column", gap: 18, marginBlockEnd: 48 }
  , section:
      { marginBlockEnd: 48
      , scrollMarginTop:
          StyleX.conditionalValue 32 [ StyleX.conditionalCase breakpoints.upTo1160 80 ]
      }
  , heading:
      { fontSize: "1.5625em"
      , color: "var(--text-primary)"
      , fontWeight: 600
      , letterSpacing: "-0.025em"
      , lineHeight: 1.25
      , marginBlockEnd: 20
      }
  , body: { display: "flex", flexDirection: "column", gap: 18 }
  , skip:
      { position: "fixed"
      , top: { default: "-100px", ":focus": "12px" }
      , left: 24
      , backgroundColor: "var(--surface-2)"
      , padding: 12
      , color: "var(--text-primary)"
      , zIndex: 30
      }
  }

styleProps = StyleX.recordProps styles

documentation :: { page :: Page, intro :: Array JSX, sections :: Array Section } -> JSX
documentation { page, intro, sections } = DOM.div styleProps.page
  [ DOM.a { className: styleProps.skip.className, href: "#content" } "Skip to content"
  , SiteNav.siteHeader { contained: false }
      [ DOM.nav { className: styleProps.headerLinks.className, "aria-label": "Site" }
          [ SiteNav.headerLink { href: "/playground/", label: "Playground", current: false }
          , SiteNav.headerLink
              { href: "https://github.com/purefunctor/purescript-iris"
              , label: "GitHub"
              , current: false
              }
          ]
      ]
  , DOM.div styleProps.layout
      [ DOM.aside styleProps.rail pageNavigation
      , DOM.div styleProps.column
          [ element navigationBarImpl
              { sections: sectionLinks
              , links
              , pages: pageNavigation
              , classes:
                  { bar: styleProps.bar.className
                  , pagesTrigger: (StyleX.props [ styles.trigger, styles.pagesTrigger ]).className
                  , pagesIcon: styleProps.barIcon.className
                  , sectionsTrigger:
                      (StyleX.props [ styles.trigger, styles.sectionsTrigger ]).className
                  , label: styleProps.barLabel.className
                  , current: styleProps.barCurrent.className
                  , chevron: (StyleX.props [ styles.barIcon, styles.chevron ]).className
                  , popover: styleProps.popover.className
                  , pagesPopover: (StyleX.props [ styles.popover, styles.pagesPopover ]).className
                  , dialog: styleProps.popoverDialog.className
                  }
              }
          , DOM.main { className: styleProps.article.className, id: "content", tabIndex: -1 }
              [ DOM.h1 styleProps.title (pageTitle page)
              , DOM.div styleProps.intro intro
              , DOM.div {} (map section sections)
              ]
          ]
      , DOM.aside (StyleX.props [ styles.rail, styles.sectionRail ])
          [ DOM.nav { "aria-label": "On this page" }
              [ DOM.p styleProps.label "On this page"
              , element sectionNavigationImpl { sections: sectionLinks, links }
              ]
          ]
      ]
  ]
  where
  sectionLinks = map (\{ id, title } -> { id, title }) sections
  links =
    { listClassName: styleProps.links.className
    , className: styleProps.link.className
    , currentClassName: (StyleX.props [ styles.link, styles.current ]).className
    , canvasClassName: NavigationLink.classNames.canvas
    , contentClassName: NavigationLink.classNames.content
    }
  pageNavigation = DOM.nav { "aria-label": "Documentation" }
    [ DOM.p styleProps.label "Pages"
    , DOM.div styleProps.links (map pageLink pages)
    , DOM.p styleProps.label "Resources"
    , resources
    ]
  pageLink entry = NavigationLink.navigationLink
    { href: pageHref entry
    , className:
        (StyleX.props [ styles.link, StyleX.conditional (entry == page) styles.current ]).className
    , current: entry == page
    , content: DOM.text (pageTitle entry)
    }
  resources = DOM.div styleProps.links
    [ resource "https://github.com/purefunctor/purescript-iris" "Compiler source"
    , resource "https://github.com/purefunctor/purescript-iris/releases" "Releases"
    , resource "https://pursuit.purescript.org" "Library documentation"
    ]
  resource href label = NavigationLink.navigationLink
    { href
    , className: styleProps.link.className
    , current: false
    , content: fragment
        [ DOM.text label
        , DOM.span styleProps.resourceIcon
            (element Icon.externalLink { "aria-hidden": true, focusable: false })
        ]
    }
  section { id, title: heading, body } = DOM.section { className: styleProps.section.className, id }
    [ DOM.h2 styleProps.heading heading, DOM.div styleProps.body body ]
