module Website.Components.Documentation (Section, documentation) where

import Prelude

import Iris.StyleX as StyleX
import React.Basic (JSX, ReactComponent, element)
import Website.Breakpoints (breakpoints)
import Website.Components.Icon as Icon
import Website.Components.SiteNav as SiteNav
import Yoga.React.DOM as DOM

type Section = { id :: String, title :: String, body :: Array JSX }

foreign import navigationLinkImpl ::
  ReactComponent
    { href :: String
    , className :: String
    , contentClassName :: String
    , current :: Boolean
    , content :: Array JSX
    }

foreign import mobileSidebarImpl ::
  ReactComponent
    { rootClassName :: String
    , triggerClassName :: String
    , overlayClassName :: String
    , modalClassName :: String
    , dialogClassName :: String
    , headClassName :: String
    , titleClassName :: String
    , closeClassName :: String
    , navigation :: Array JSX
    }

slideIn =
  StyleX.keyframes
    { from: { transform: "translateX(-100%)" }
    , to: { transform: "translateX(0)" }
    }
slideOut =
  StyleX.keyframes
    { from: { transform: "translateX(0)" }
    , to: { transform: "translateX(-100%)" }
    }
fadeIn = StyleX.keyframes { from: { opacity: 0 }, to: { opacity: 1 } }
fadeOut = StyleX.keyframes { from: { opacity: 1 }, to: { opacity: 0 } }

styles =
  StyleX.create
    { layout:
        { display: "grid"
        , gridTemplateColumns:
            StyleX.conditionalValue
              "210px minmax(0, 720px) max-content"
              [ StyleX.conditionalCase breakpoints.upTo960 "minmax(0, 1fr)"
              , StyleX.conditionalCase
                  breakpoints.above960To1160
                  "210px minmax(0, 720px)"
              ]
        , columnGap: "clamp(32px, 4vw, 64px)"
        , rowGap: 32
        , marginInline: "auto"
        , maxWidth: "var(--container-wide)"
        , paddingInline: "var(--gutter)"
        , paddingBlockStart:
            StyleX.conditionalValue
              64
              [ StyleX.conditionalCase breakpoints.upTo960 24 ]
        , paddingBlockEnd: 80
        , alignItems: "start"
        }
    , sidebar:
        { display:
            StyleX.conditionalValue
              "block"
              [ StyleX.conditionalCase breakpoints.upTo960 "none" ]
        , position:
            StyleX.conditionalValue
              "sticky"
              [ StyleX.conditionalCase breakpoints.upTo960 "static" ]
        , top: "calc(var(--nav-height) + 64px)"
        -- Match the layout's top and bottom padding, including at the page end.
        , maxHeight:
            StyleX.conditionalValue
              "calc(100dvh - var(--nav-height) - 64px - 80px)"
              [ StyleX.conditionalCase breakpoints.upTo960 "none" ]
        , overflowY:
            StyleX.conditionalValue
              "auto"
              [ StyleX.conditionalCase breakpoints.upTo960 "visible" ]
        , minWidth: 0
        }
    , trigger:
        { backgroundColor:
            { default: "transparent", ":hover": "var(--surface-2)" }
        , display: "inline-flex"
        , alignItems: "center"
        , justifyContent: "center"
        , height: 44
        , width: 44
        , borderRadius: "50%"
        , cursor: "default"
        , fontSize: 18
        , color: "var(--text-primary)"
        , outlineColor: "var(--focus-ring)"
        }
    , headerTitle:
        { display:
            StyleX.conditionalValue
              "block"
              [ StyleX.conditionalCase breakpoints.upTo480 "none" ]
        , color: "var(--text-secondary)"
        , fontSize: 14
        , fontWeight: 500
        }
    , mobileMenu:
        { display:
            StyleX.conditionalValue
              "none"
              [ StyleX.conditionalCase breakpoints.upTo960 "block" ]
        , marginInlineStart: "auto"
        }
    , navigation:
        { display:
            StyleX.conditionalValue
              "block"
              [ StyleX.conditionalCase breakpoints.upTo960 "none" ]
        }
    , overlay:
        { position: "fixed"
        , inset: 0
        , zIndex: 40
        , display: "flex"
        , backgroundColor: "var(--overlay-scrim)"
        , animationName:
            { default: "none"
            , "[data-entering]": fadeIn
            , "[data-exiting]": fadeOut
            }
        , animationDuration:
            { default: "180ms"
            , "@media (prefers-reduced-motion: reduce)": "0ms"
            }
        }
    , modal:
        { backgroundColor: "var(--loam-900)"
        , width: "min(340px, calc(100vw - 40px))"
        , height: "100dvh"
        , overflowY: "auto"
        , animationName:
            { default: "none"
            , "[data-entering]": slideIn
            , "[data-exiting]": slideOut
            }
        , animationDuration:
            { default: "180ms"
            , "@media (prefers-reduced-motion: reduce)": "0ms"
            }
        , animationTimingFunction: "var(--ease-out)"
        }
    , dialog: { padding: 24, outline: "none" }
    , drawerHead:
        { display: "flex"
        , alignItems: "center"
        , justifyContent: "space-between"
        , gap: 12
        , marginBlockEnd: 32
        }
    , drawerTitle:
        { fontSize: 21
        , fontWeight: 600
        , color: "var(--text-primary)"
        , letterSpacing: "-0.025em"
        }
    , close:
        { display: "inline-flex"
        , alignItems: "center"
        , justifyContent: "center"
        , height: 36
        , width: 36
        , backgroundColor:
            { default: "var(--surface-1)", ":hover": "var(--surface-2)" }
        , color: "var(--text-primary)"
        , borderRadius: "50%"
        , cursor: "default"
        , outlineColor: "var(--focus-ring)"
        }
    , tabletToc:
        { display:
            StyleX.conditionalValue
              "none"
              [ StyleX.conditionalCase breakpoints.above960To1160 "block" ]
        }
    , label:
        { fontSize: 13
        , fontWeight: 600
        , color: "var(--text-primary)"
        , marginBlockEnd: 14
        }
    , navigationTitle:
        { fontSize: 21
        , fontWeight: 600
        , letterSpacing: "-0.025em"
        , color: "var(--text-primary)"
        , marginBlockEnd: 24
        }
    , links:
        { display: "flex", flexDirection: "column", gap: 4, marginBlockEnd: 32 }
    , link:
        { position: "relative"
        , isolation: "isolate"
        , backgroundColor:
            { default: "transparent", ":hover": "var(--surface-1)" }
        , color:
            { default: "var(--text-secondary)"
            , ":hover": "var(--text-primary)"
            }
        , cursor: "default"
        , display: "flex"
        , alignItems: "center"
        , justifyContent: "space-between"
        , gap: 10
        , paddingBlock: 8
        , paddingInline: 12
        , fontSize: 14
        , textDecoration: "none"
        , outlineColor: "var(--focus-ring)"
        }
    , current:
        { backgroundColor:
            { default: "var(--accent-soft)", ":hover": "var(--surface-2)" }
        , color: "var(--iris-200)"
        , fontWeight: 600
        }
    , linkContent:
        { position: "relative"
        , zIndex: 1
        , display: "flex"
        , alignItems: "center"
        , justifyContent: "space-between"
        , gap: 10
        , width: "100%"
        , minWidth: 0
        }
    , resourceIcon:
        { display: "inline-flex"
        , flexShrink: 0
        , fontSize: 11
        , color: "var(--text-tertiary)"
        }
    , article: { minWidth: 0 }
    , title:
        { fontSize: "clamp(38px, 4vw, 54px)"
        , color: "var(--text-primary)"
        , fontWeight: 650
        , letterSpacing: "-0.045em"
        , lineHeight: 1.1
        , marginBlockEnd: 20
        }
    , intro:
        { fontSize: 19
        , color: "var(--text-secondary)"
        , lineHeight: 1.65
        , maxWidth: "60ch"
        , marginBlockEnd: 48
        }
    , section:
        { marginBlockEnd: 48
        , scrollMarginTop: "calc(var(--nav-height) + 28px)"
        }
    , heading:
        { fontSize: 25
        , color: "var(--text-primary)"
        , fontWeight: 600
        , letterSpacing: "-0.025em"
        , lineHeight: 1.25
        , marginBlockEnd: 20
        }
    , body: { display: "flex", flexDirection: "column", gap: 18 }
    , toc:
        { display:
            StyleX.conditionalValue
              "block"
              [ StyleX.conditionalCase breakpoints.upTo1160 "none" ]
        , position: "sticky"
        , top: "calc(var(--nav-height) + 64px)"
        , maxHeight: "calc(100dvh - var(--nav-height) - 64px - 80px)"
        , overflowY: "auto"
        , fontSize: 13
        , width: "28ch"
        }
    , tocLink:
        { color:
            { default: "var(--text-tertiary)", ":hover": "var(--text-primary)" }
        , display: "block"
        , fontSize: 13
        , paddingBlock: 6
        , textDecoration: "none"
        , outlineColor: "var(--focus-ring)"
        }
    , footer:
        { color: "var(--text-tertiary)", fontSize: 13, marginBlockStart: 64 }
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

documentation ::
  { title :: String, intro :: String, sections :: Array Section } -> JSX
documentation { title, intro, sections } =
  DOM.div
    {}
    [ DOM.a
        { className: styleProps.skip.className, href: "#content" }
        "Skip to content"
    , SiteNav.siteHeader
        [ DOM.p styleProps.headerTitle "Documentation"
        , element
            mobileSidebarImpl
            { rootClassName: styleProps.mobileMenu.className
            , triggerClassName: styleProps.trigger.className
            , overlayClassName: styleProps.overlay.className
            , modalClassName: styleProps.modal.className
            , dialogClassName: styleProps.dialog.className
            , headClassName: styleProps.drawerHead.className
            , titleClassName: styleProps.drawerTitle.className
            , closeClassName: styleProps.close.className
            , navigation:
                guide
                  <> [ DOM.p styleProps.label "On this page"
                     , DOM.div styleProps.links (map sidebarAnchor sections)
                     ]
                  <> resources
            }
        ]
    , DOM.div
        styleProps.layout
        [ DOM.aside
            styleProps.sidebar
            [ DOM.nav
                { className: styleProps.navigation.className
                , "aria-label": "Documentation"
                }
                (
                  [ DOM.p styleProps.navigationTitle "Documentation" ]
                    <> guide
                    <> resources
                    <> [ DOM.div
                           styleProps.tabletToc
                           [ DOM.p styleProps.label "In this guide"
                           , DOM.div
                               styleProps.links
                               (map sidebarAnchor sections)
                           ]
                       ]
                )
            ]
        , DOM.main
            { className: styleProps.article.className
            , id: "content"
            , tabIndex: -1
            }
            [ DOM.h1 styleProps.title title
            , DOM.p styleProps.intro intro
            , DOM.div {} (map section sections)
            , DOM.footer
                styleProps.footer
                "Iris is in alpha. Commands and APIs may change between releases."
            ]
        , DOM.nav
            { className: styleProps.toc.className
            , "aria-label": "On this page"
            }
            ([ DOM.p styleProps.label "On this page" ] <> map anchor sections)
        ]
    ]
  where
  guide =
    [ DOM.div
        styleProps.links
        [ navigationLink
            "/docs/getting-started"
            true
            [ DOM.text "Getting started" ]
        ]
    ]
  resources =
    [ DOM.p styleProps.label "Resources"
    , DOM.div
        styleProps.links
        [ resource
            "https://github.com/purefunctor/purescript-iris"
            "Compiler source"
        , resource
            "https://github.com/purefunctor/purescript-iris/releases"
            "Releases"
        , resource "https://pursuit.purescript.org" "Library documentation"
        ]
    ]
  resource href label =
    navigationLink
      href
      false
      [ DOM.text label
      , DOM.span
          styleProps.resourceIcon
          (element Icon.externalLink { "aria-hidden": true, focusable: false })
      ]
  navigationLink href current content =
    element
      navigationLinkImpl
      { href
      , className:
          (
            StyleX.props
              [ styles.link, StyleX.conditional current styles.current ]
          ).className
      , contentClassName: styleProps.linkContent.className
      , current
      , content
      }
  sidebarAnchor { id, title: label } =
    navigationLink ("#" <> id) false [ DOM.text label ]
  anchor { id, title: label } =
    DOM.a { className: styleProps.tocLink.className, href: "#" <> id } label
  section { id, title: heading, body } =
    DOM.section
      { className: styleProps.section.className, id }
      [ DOM.h2 styleProps.heading heading, DOM.div styleProps.body body ]
