module Website.Components.Documentation (Page(..), Section, documentation) where

import Prelude

import Data.Array (findIndex, (!!))
import Data.Maybe (maybe)
import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element, fragment)
import Website.Breakpoints (breakpoints)
import Website.Components.Icon as Icon
import Website.Components.NavigationLink as NavigationLink
import Website.Components.SiteNav as SiteNav
import Yoga.React.DOM as DOM

data Page = GettingStarted | Installation | LanguageServer | Formatting

derive instance Eq Page

-- | Pages in header navigation and previous/next order. The compiler README links to these
-- | routes.
pages :: Array Page
pages = [ GettingStarted, Installation, LanguageServer, Formatting ]

-- | Production serves each page at its trailing-slash URL and redirects the bare form, so links
-- | use that URL to avoid a round trip.
pageHref :: Page -> String
pageHref = case _ of
  GettingStarted -> "/docs/getting-started/"
  Installation -> "/docs/installation/"
  LanguageServer -> "/docs/language-server/"
  Formatting -> "/docs/formatting/"

pageTitle :: Page -> String
pageTitle = case _ of
  GettingStarted -> "Getting started"
  Installation -> "Installation"
  LanguageServer -> "Language server"
  Formatting -> "Formatting"

type Section = { id :: String, title :: String, body :: Array JSX }

type SectionLink = { id :: String, title :: String }

type Links =
  { listClassName :: String
  , className :: String
  , currentClassName :: String
  , canvasClassName :: String
  , contentClassName :: String
  }

foreign import pageNavigationImpl ::
  ReactComponent { className :: String, label :: String, content :: JSX }

foreign import sectionNavigationImpl ::
  ReactComponent { sections :: Array SectionLink, links :: Links }

foreign import sectionMenuImpl ::
  ReactComponent
    { sections :: Array SectionLink
    , links :: Links
    , rootClassName :: String
    , triggerClassName :: String
    , labelClassName :: String
    , currentClassName :: String
    , iconClassName :: String
    , popoverClassName :: String
    , dialogClassName :: String
    , headingClassName :: String
    , resources :: JSX
    }

foreign import sectionSidebarImpl ::
  ReactComponent
    { sections :: Array SectionLink
    , links :: Links
    , rootClassName :: String
    , buttonClassName :: String
    , closeClassName :: String
    , overlayClassName :: String
    , panelClassName :: String
    , dialogClassName :: String
    , labelClassName :: String
    , resources :: JSX
    }

fadeIn = StyleX.keyframes { from: { opacity: 0 }, to: { opacity: 1 } }
fadeOut = StyleX.keyframes { from: { opacity: 1 }, to: { opacity: 0 } }
slideIn =
  StyleX.keyframes { from: { transform: "translateX(-100%)" }, to: { transform: "translateX(0)" } }
slideOut =
  StyleX.keyframes { from: { transform: "translateX(0)" }, to: { transform: "translateX(-100%)" } }

styles =
  StyleX.create
    { page: { fontSize: 16, lineHeight: 1.75, color: "var(--text-secondary)" }
    -- On narrow screens the page links scroll within the header, out to the viewport's edge.
    , pageNavigation:
        { display: "flex"
        , position: "relative"
        , alignSelf: "stretch"
        , minWidth: 0
        , marginInlineEnd: "calc(-1 * var(--gutter))"
        , overflowX: "auto"
        , scrollbarWidth: "none"
        , maskImage:
            { default: "none"
            , "[data-fade=start]": "linear-gradient(to right, transparent, black 48px)"
            , "[data-fade=end]": "linear-gradient(to left, transparent, black 48px)"
            , "[data-fade=both]":
                "linear-gradient(to right, transparent, black 48px, black calc(100% - 48px), transparent)"
            }
        }
    , menu:
        { display:
            StyleX.conditionalValue "none" [ StyleX.conditionalCase breakpoints.upTo720 "block" ]
        , position: "sticky"
        , top: "var(--nav-height)"
        , zIndex: 15
        , backgroundColor: "var(--granite-900)"
        }
    , menuTrigger:
        { display: "flex"
        , alignItems: "center"
        , gap: 12
        , width: "100%"
        , height: 48
        , paddingInline: "var(--gutter)"
        , backgroundColor: { default: "transparent", ":hover": "var(--surface-1)" }
        , color: "var(--text-primary)"
        , cursor: "default"
        , fontSize: 14
        , textAlign: "start"
        , outlineColor: "var(--focus-ring)"
        , outlineOffset: -2
        }
    , menuLabel: { flexShrink: 0, fontWeight: 600 }
    , menuCurrent:
        { minWidth: 0
        , overflow: "hidden"
        , textOverflow: "ellipsis"
        , whiteSpace: "nowrap"
        , color: "var(--text-tertiary)"
        }
    , menuIcon:
        { flexShrink: 0, marginInlineStart: "auto", fontSize: 16, color: "var(--text-tertiary)" }
    , popover:
        { width: "var(--trigger-width)"
        , overflowY: "auto"
        , backgroundColor: "var(--granite-900)"
        , boxShadow: "0 28px 40px -20px oklch(0% 0 0 / 70%)"
        , outline: "none"
        , animationName: { default: "none", "[data-entering]": fadeIn, "[data-exiting]": fadeOut }
        , animationDuration: { default: "140ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
        }
    , popoverDialog:
        { paddingInline: "calc(var(--gutter) - 12px)"
        , paddingBlockStart: 8
        , paddingBlockEnd: 16
        , outline: "none"
        }
    , layout:
        { display: "grid"
        , gridTemplateColumns:
            StyleX.conditionalValue
              "var(--rail-width) minmax(0, 1fr)"
              [ StyleX.conditionalCase breakpoints.above720To960 "64px minmax(0, 1fr)"
              , StyleX.conditionalCase breakpoints.upTo720 "minmax(0, 1fr)"
              ]
        , alignItems: "start"
        }
    , rail:
        { display:
            StyleX.conditionalValue "block" [ StyleX.conditionalCase breakpoints.upTo960 "none" ]
        , position: "sticky"
        , top: "var(--nav-height)"
        , height: "calc(100dvh - var(--nav-height))"
        , overflowY: "auto"
        , backgroundColor: "var(--granite-900)"
        , paddingInline: "calc(var(--gutter) - 12px)"
        , paddingBlockStart: 64
        , paddingBlockEnd: 32
        }
    -- On tablets the rail collapses to a floating button, in line with the brand, that slides it out
    -- over the article.
    , collapsedRail:
        { display:
            StyleX.conditionalValue
              "none"
              [ StyleX.conditionalCase breakpoints.above720To960 "block" ]
        , position: "sticky"
        , top: "var(--nav-height)"
        , height: "calc(100dvh - var(--nav-height))"
        , paddingInlineStart: "var(--gutter)"
        , paddingBlockStart: 16
        }
    , sidebarButton:
        { display: "inline-flex"
        , alignItems: "center"
        , justifyContent: "center"
        , width: 40
        , height: 40
        , backgroundColor: { default: "var(--surface-1)", ":hover": "var(--surface-2)" }
        , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
        , cursor: "default"
        , fontSize: 18
        , outlineColor: "var(--focus-ring)"
        }
    , sidebarClose: { marginInlineStart: 12, marginBlockEnd: 32 }
    , sidebarOverlay:
        { position: "fixed"
        , insetBlockStart: "var(--nav-height)"
        , insetBlockEnd: 0
        , insetInline: 0
        , zIndex: 40
        , display: "flex"
        , backgroundColor: "var(--overlay-scrim)"
        , animationName: { default: "none", "[data-entering]": fadeIn, "[data-exiting]": fadeOut }
        , animationDuration: { default: "180ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
        }
    , sidebarPanel:
        { width: "var(--rail-width)"
        , height: "100%"
        , overflowY: "auto"
        , backgroundColor: "var(--granite-900)"
        , animationName: { default: "none", "[data-entering]": slideIn, "[data-exiting]": slideOut }
        , animationDuration: { default: "180ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
        , animationTimingFunction: "var(--ease-out)"
        }
    , sidebarDialog:
        { paddingInline: 12, paddingBlockStart: 16, paddingBlockEnd: 32, outline: "none" }
    , label:
        { fontSize: 13
        , fontWeight: 600
        , color: "var(--text-primary)"
        , paddingInline: 12
        , marginBlockEnd: 10
        }
    , popoverLabel: { marginBlockStart: 20 }
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
    -- Keep the regular weight so marking a section never rewraps its title.
    , current:
        { color: "var(--text-primary)"
        , textDecorationLine: "underline"
        , textDecorationColor: "var(--accent)"
        , textDecorationThickness: 1
        , textUnderlineOffset: 6
        }
    , resourceIcon:
        { display: "inline-flex", flexShrink: 0, fontSize: 11, color: "var(--text-tertiary)" }
    -- Text, terminals and code blocks share one 72ch measure. Text grows on wide screens so the
    -- article can widen without longer lines.
    , article:
        { justifySelf: "center"
        , width: "100%"
        , minWidth: 0
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
    , intro:
        { fontSize: "1.1875em"
        , color: "var(--text-secondary)"
        , lineHeight: 1.65
        , marginBlockEnd: 48
        }
    -- Clear the sticky header, and on narrow screens the section menu below it.
    , section:
        { marginBlockEnd: 48
        , scrollMarginTop:
            StyleX.conditionalValue 32 [ StyleX.conditionalCase breakpoints.upTo720 80 ]
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
    , footer: { display: "flex", flexDirection: "column", gap: 32, marginBlockStart: 72 }
    , pager:
        { display: "grid"
        , gridTemplateColumns:
            StyleX.conditionalValue
              "repeat(2, minmax(0, 1fr))"
              [ StyleX.conditionalCase breakpoints.upTo480 "minmax(0, 1fr)" ]
        , gap: 12
        }
    , pagerLink:
        { display: "flex"
        , flexDirection: "column"
        , gap: 2
        , paddingBlock: 16
        , paddingInline: 20
        , backgroundColor: { default: "var(--surface-1)", ":hover": "var(--surface-2)" }
        , cursor: "default"
        , textDecoration: "none"
        , outlineColor: "var(--focus-ring)"
        }
    , pagerNext:
        { gridColumnStart:
            StyleX.conditionalValue 2 [ StyleX.conditionalCase breakpoints.upTo480 1 ]
        , alignItems: "flex-end"
        , textAlign: "end"
        }
    , pagerLabel: { fontSize: 13, color: "var(--text-tertiary)" }
    , pagerTitle:
        { fontSize: 17, fontWeight: 600, letterSpacing: "-0.015em", color: "var(--text-primary)" }
    , notice: { color: "var(--text-tertiary)", fontSize: 13 }
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

documentation :: { page :: Page, intro :: String, sections :: Array Section } -> JSX
documentation { page, intro, sections } =
  DOM.div
    styleProps.page
    [ DOM.a { className: styleProps.skip.className, href: "#content" } "Skip to content"
    , SiteNav.siteHeader
        { contained: false }
        [ element
            pageNavigationImpl
            { className: styleProps.pageNavigation.className
            , label: "Documentation"
            , content: fragment (map pageLink pages)
            }
        ]
    , element
        sectionMenuImpl
        { sections: sectionLinks
        , links
        , rootClassName: styleProps.menu.className
        , triggerClassName: styleProps.menuTrigger.className
        , labelClassName: styleProps.menuLabel.className
        , currentClassName: styleProps.menuCurrent.className
        , iconClassName: styleProps.menuIcon.className
        , popoverClassName: styleProps.popover.className
        , dialogClassName: styleProps.popoverDialog.className
        , headingClassName: (StyleX.props [ styles.label, styles.popoverLabel ]).className
        , resources
        }
    , DOM.div
        styleProps.layout
        [ DOM.aside
            styleProps.rail
            [ DOM.nav
                { "aria-label": "On this page" }
                [ DOM.p styleProps.label "On this page"
                , element sectionNavigationImpl { sections: sectionLinks, links }
                ]
            , DOM.p styleProps.label "Resources"
            , resources
            ]
        , element
            sectionSidebarImpl
            { sections: sectionLinks
            , links
            , rootClassName: styleProps.collapsedRail.className
            , buttonClassName: styleProps.sidebarButton.className
            , closeClassName: (StyleX.props [ styles.sidebarButton, styles.sidebarClose ]).className
            , overlayClassName: styleProps.sidebarOverlay.className
            , panelClassName: styleProps.sidebarPanel.className
            , dialogClassName: styleProps.sidebarDialog.className
            , labelClassName: styleProps.label.className
            , resources
            }
        , DOM.main
            { className: styleProps.article.className, id: "content", tabIndex: -1 }
            [ DOM.h1 styleProps.title (pageTitle page)
            , DOM.p styleProps.intro intro
            , DOM.div {} (map section sections)
            , DOM.footer
                styleProps.footer
                [ DOM.nav
                    { className: styleProps.pager.className
                    , "aria-label": "Previous and next pages"
                    }
                    (pagerLink "Previous" false (offset (-1)) <> pagerLink "Next" true (offset 1))
                , DOM.p
                    styleProps.notice
                    "Iris is in alpha. Commands and APIs may change between releases."
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
  pageLink entry =
    SiteNav.headerLink { href: pageHref entry, label: pageTitle entry, current: entry == page }
  offset by = findIndex (_ == page) pages >>= \index -> pages !! (index + by)
  pagerLink label next =
    maybe
      []
      \entry ->
        [ DOM.a
            { className:
                ( StyleX.props [ styles.pagerLink, StyleX.conditional next styles.pagerNext ]
                ).className
            , href: pageHref entry
            }
            [ DOM.span styleProps.pagerLabel label
            , DOM.span styleProps.pagerTitle (pageTitle entry)
            ]
        ]
  resources =
    DOM.div
      styleProps.links
      [ resource "https://github.com/purefunctor/purescript-iris" "Compiler source"
      , resource "https://github.com/purefunctor/purescript-iris/releases" "Releases"
      , resource "https://pursuit.purescript.org" "Library documentation"
      ]
  resource href label =
    NavigationLink.navigationLink
      { href
      , className: styleProps.link.className
      , current: false
      , content:
          fragment
            [ DOM.text label
            , DOM.span
                styleProps.resourceIcon
                (element Icon.externalLink { "aria-hidden": true, focusable: false })
            ]
      }
  section { id, title: heading, body } =
    DOM.section
      { className: styleProps.section.className, id }
      [ DOM.h2 styleProps.heading heading, DOM.div styleProps.body body ]
