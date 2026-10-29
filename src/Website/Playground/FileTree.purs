module Website.Playground.FileTree (fileTree) where

import Prelude

import Data.Array (last, snoc, sortBy, uncons)
import Data.Array as Array
import Data.Foldable (foldl, for_, sum)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe, isJust, isNothing)
import Data.Nullable (Nullable, notNull, null, toMaybe)
import Data.Set (Set)
import Data.Set as Set
import Data.String (Pattern(..), drop, lastIndexOf, localeCompare, split)
import Data.Tuple (Tuple(..), fst)
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Iris.StyleX as StyleX
import Iris.StyleX.When as When
import React.Basic (JSX, ReactComponent, Ref, element)
import React.Basic.Events (EventFn, SyntheticEvent, handler, handler_, unsafeEventFn)
import React.Basic.Hooks as Hooks
import Unsafe.Coerce (unsafeCoerce)
import Web.DOM.Element (Element, getBoundingClientRect)
import Web.HTML.HTMLInputElement as HTMLInputElement
import Website.Jotai as Jotai
import Website.Playground.Types (Actions, File, Viewer)
import Yoga.React.DOM as DOM

type IconProps = { "aria-hidden" :: Boolean, className :: String }

foreign import chevronRightIcon :: ReactComponent IconProps

foreign import filePlusIcon :: ReactComponent { "aria-hidden" :: Boolean }

foreign import pencilIcon :: ReactComponent { "aria-hidden" :: Boolean }

foreign import trashIcon :: ReactComponent { "aria-hidden" :: Boolean }

foreign import fileIcon :: ReactComponent IconProps

foreign import javaScriptIcon :: ReactComponent IconProps

foreign import pureScriptIcon :: ReactComponent IconProps

foreign import reactIcon :: ReactComponent IconProps

foreign import portalToBody :: JSX -> JSX

listIn = StyleX.keyframes
  { from: { opacity: 0, transform: "translateY(-3px)" }, to: { opacity: 1, transform: "none" } }

styles = StyleX.create
  { root:
      { backgroundColor: "var(--granite-950)"
      , display: "flex"
      , flexBasis: 0
      , flexDirection: "column"
      , flexGrow: 1
      , minHeight: 0
      }
  , header:
      { alignItems: "center"
      , display: "flex"
      , flexShrink: 0
      , height: 36
      , justifyContent: "space-between"
      , paddingInlineEnd: 6
      , paddingInlineStart: 14
      }
  , title: { color: "var(--text-tertiary)", fontSize: 12, fontWeight: 600, margin: 0 }
  , scroll: { flexGrow: 1, minHeight: 0, overflowY: "auto", paddingBlockEnd: 12 }
  , list:
      { animationDuration: "180ms"
      , animationName: { default: listIn, "@media (prefers-reduced-motion: reduce)": "none" }
      , animationTimingFunction: "var(--ease-out)"
      , listStyle: "none"
      , margin: 0
      , padding: 0
      }
  , item: { position: "relative" }
  , row:
      { alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-1)" }
      , borderStyle: "none"
      , color: { default: "var(--text-secondary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , display: "flex"
      , fontFamily: "var(--font-mono)"
      , fontSize: 13
      , gap: 6
      , height: 28
      , outlineColor: "var(--focus-ring)"
      , outlineOffset: -2
      , outlineStyle: { default: "none", ":focus-visible": "solid" }
      , outlineWidth: 2
      , paddingInlineEnd: 64
      , paddingInlineStart: "calc(10px + var(--depth) * 14px)"
      , textAlign: "start"
      , transitionDuration: "120ms"
      , transitionProperty: "background-color, color"
      , transitionTimingFunction: "var(--ease-out)"
      , width: "100%"
      }
  , activeRow:
      { backgroundColor: { default: "var(--surface-2)", ":hover": "var(--surface-2)" }
      , boxShadow: "inset 2px 0 0 var(--accent)"
      , color: { default: "var(--text-primary)", ":hover": "var(--text-primary)" }
      }
  , chevron:
      { color: "var(--text-tertiary)"
      , flexShrink: 0
      , fontSize: 14
      , transitionDuration: { default: "120ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
      , transitionProperty: "transform"
      }
  , openChevron: { transform: "rotate(90deg)" }
  , icon: { flexShrink: 0, height: 16, width: 16 }
  , name: { minWidth: 0, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }
  , count:
      { borderRadius: 999
      , flexShrink: 0
      , fontFamily: "var(--font-sans)"
      , fontSize: 11
      , fontWeight: 600
      , lineHeight: "16px"
      , minWidth: 16
      , paddingInline: 5
      , textAlign: "center"
      }
  , errorCount: { backgroundColor: "var(--red-300)", color: "var(--granite-950)" }
  , warningCount: { backgroundColor: "var(--yellow-400)", color: "var(--granite-950)" }
  , errorDot:
      { backgroundColor: "var(--red-300)", borderRadius: 999, flexShrink: 0, height: 7, width: 7 }
  , actions:
      { display: "flex"
      , gap: 2
      , insetBlockStart: 2
      , insetInlineEnd: 6
      , opacity: StyleX.conditionalValue 0.0
          [ When.ancestor ":hover" 1.0
          , When.ancestor ":focus-within" 1.0
          , StyleX.conditionalCase "@media (hover: none)" 1.0
          ]
      , position: "absolute"
      , transitionDuration: { default: "120ms", "@media (prefers-reduced-motion: reduce)": "0ms" }
      , transitionProperty: "opacity"
      , transitionTimingFunction: "var(--ease-out)"
      }
  , action:
      { alignItems: "center"
      , backgroundColor: { default: "transparent", ":hover": "var(--surface-3)" }
      , borderRadius: 4
      , borderStyle: "none"
      , boxShadow: { default: "none", ":focus-visible": "var(--shadow-focus)" }
      , color: { default: "var(--text-tertiary)", ":hover": "var(--text-primary)" }
      , cursor: "default"
      , display: "inline-flex"
      , fontSize: 12
      , height: 24
      , justifyContent: "center"
      , outline: { default: "revert", ":focus-visible": "none" }
      , width: 24
      }
  , input:
      { backgroundColor: "var(--granite-950)"
      , borderColor: "var(--accent)"
      , borderRadius: 4
      , borderStyle: "solid"
      , borderWidth: 1
      , boxSizing: "border-box"
      , color: "var(--text-primary)"
      , display: "block"
      , fontFamily: "var(--font-mono)"
      , fontSize: 13
      , height: 28
      , marginInlineStart: "calc(6px + var(--depth) * 14px)"
      , outlineStyle: "none"
      , paddingInline: 6
      , width: "calc(100% - 12px - var(--depth) * 14px)"
      }
  , problem:
      { backgroundColor: "var(--red-300)"
      , color: "var(--granite-950)"
      , fontSize: 12
      , fontWeight: 500
      , maxWidth: 320
      , paddingBlock: 6
      , paddingInline: 10
      , position: "fixed"
      , zIndex: 30
      }
  }

styleProps = StyleX.recordProps styles

newtype Folder = Folder { path :: String, folders :: Map String Folder, files :: Array TreeFile }

type TreeFile = { path :: String, name :: String, errors :: Int, warnings :: Int }

emptyFolder :: String -> Folder
emptyFolder path = Folder { path, folders: Map.empty, files: [] }

buildTree :: Array File -> Folder
buildTree =
  foldl (\root file -> insertFile file "" (split (Pattern "/") file.path) root) (emptyFolder "")

insertFile :: File -> String -> Array String -> Folder -> Folder
insertFile file prefix segments folder = case uncons segments of
  Just { head, tail }
    | not (Array.null tail) -> insertIntoSubfolder file (joinPath prefix head) head tail folder
  _ -> addFile file folder

insertIntoSubfolder :: File -> String -> String -> Array String -> Folder -> Folder
insertIntoSubfolder file path name rest =
  withFolders (Map.alter (Just <<< insertFile file path rest <<< fromMaybe (emptyFolder path)) name)

withFolders :: (Map String Folder -> Map String Folder) -> Folder -> Folder
withFolders update (Folder folder) = Folder folder { folders = update folder.folders }

addFile :: File -> Folder -> Folder
addFile file (Folder folder) = Folder folder { files = snoc folder.files (treeFile file) }

treeFile :: File -> TreeFile
treeFile file =
  { path: file.path
  , name: fromMaybe file.path (last (split (Pattern "/") file.path))
  , errors: file.errors
  , warnings: file.warnings
  }

joinPath :: String -> String -> String
joinPath prefix segment = if prefix == "" then segment else prefix <> "/" <> segment

errorsIn :: Folder -> Int
errorsIn (Folder folder) =
  sum (map _.errors folder.files) + sum (map errorsIn (Map.values folder.folders))

iconFor :: String -> ReactComponent IconProps
iconFor name = case lastIndexOf (Pattern ".") name of
  Just dot
    | dot > 0 -> case drop (dot + 1) name of
      "purs" -> pureScriptIcon
      "js" -> javaScriptIcon
      "jsx" -> reactIcon
      _ -> fileIcon
  _ -> fileIcon

collapsedAtom :: Jotai.Atom (Set String)
collapsedAtom = unsafePerformEffect (Jotai.atom Set.empty)

editingAtom :: Jotai.Atom (Maybe String)
editingAtom = unsafePerformEffect (Jotai.atom Nothing)

draftAtom :: Jotai.Atom String
draftAtom = unsafePerformEffect (Jotai.atom "")

problemAtom :: Jotai.Atom (Maybe String)
problemAtom = unsafePerformEffect (Jotai.atom Nothing)

anchorAtom :: Jotai.Atom (Maybe { top :: Number, left :: Number })
anchorAtom = unsafePerformEffect (Jotai.atom Nothing)

type Tree =
  { files :: Array File
  , active :: Nullable String
  , viewing :: Nullable Viewer
  , actions :: Actions
  , collapsed :: Set String
  , editing :: Maybe String
  , draft :: String
  , problem :: Maybe String
  , anchor :: Maybe { top :: Number, left :: Number }
  , input :: Ref (Nullable Element)
  , toggle :: String -> Effect Unit
  , startRename :: String -> Effect Unit
  , editDraft :: String -> Effect Unit
  , commit :: String -> Effect Unit
  , cancel :: Effect Unit
  }

fileTree ::
  ReactComponent
    { files :: Array File
    , active :: Nullable String
    , viewing :: Nullable Viewer
    , actions :: Actions
    }
fileTree = unsafePerformEffect $ Hooks.reactComponent "PlaygroundFileTree" \props -> Hooks.do
  collapsed /\ setCollapsed <- Jotai.useAtom collapsedAtom
  editing /\ setEditing <- Jotai.useAtom editingAtom
  draft /\ setDraft <- Jotai.useAtom draftAtom
  problem /\ setProblem <- Jotai.useAtom problemAtom
  anchor /\ setAnchor <- Jotai.useAtom anchorAtom
  input <- Hooks.useRef null
  Hooks.useEffect editing do
    when (isJust editing) do
      element' <- Hooks.readRefMaybe input
      for_ (element' >>= HTMLInputElement.fromElement) HTMLInputElement.select
    pure (pure unit)
  Hooks.useLayoutEffect problem do
    element' <- Hooks.readRefMaybe input
    case problem, element' of
      Just _, Just box -> do
        { bottom, left } <- getBoundingClientRect box
        setAnchor (const (Just { top: bottom + 6.0, left }))
      _, _ -> setAnchor (const Nothing)
    pure (pure unit)
  let
    tree :: Tree
    tree =
      { files: props.files
      , active: props.active
      , viewing: props.viewing
      , actions: props.actions
      , collapsed
      , editing
      , draft
      , problem
      , anchor
      , input
      , toggle: \path -> setCollapsed \current ->
          if Set.member path current then Set.delete path current else Set.insert path current
      , startRename: \path -> do
          setEditing (const (Just path))
          setDraft (const path)
          setProblem (const Nothing)
      , editDraft: \value -> setDraft (const value)
      , commit: \from -> do
          rejection <- props.actions.renameFile from draft
          case toMaybe rejection of
            Just message -> setProblem (const (Just message))
            Nothing -> do
              setEditing (const Nothing)
              setProblem (const Nothing)
      , cancel: setEditing (const Nothing)
      }
  pure $ DOM.nav { "aria-labelledby": "playground-files", className: styleProps.root.className }
    [ DOM.div styleProps.header
        [ DOM.h2 { className: styleProps.title.className, id: "playground-files" } "Files"
        , DOM.button
            { "aria-label": "New file"
            , className: styleProps.action.className
            , onClick: handler_ props.actions.createFile
            , title: "New file"
            , type: "button"
            }
            (element filePlusIcon { "aria-hidden": true })
        ]
    , DOM.div styleProps.scroll (folderContents tree 0 (buildTree props.files))
    ]

folderContents :: Tree -> Int -> Folder -> JSX
folderContents tree level (Folder folder) = DOM.ul styleProps.list
  ( map (folderRow tree level)
        (sortBy (\a b -> localeCompare (fst a) (fst b)) (Map.toUnfoldable folder.folders))
      <> map (fileRow tree level) (sortBy (\a b -> localeCompare a.name b.name) folder.files)
  )

folderRow :: Tree -> Int -> Tuple String Folder -> JSX
folderRow tree level (Tuple name folder@(Folder { path })) =
  let
    open :: Boolean
    open = not (Set.member path tree.collapsed)

    errors :: Int
    errors = if open then 0 else errorsIn folder
  in
    DOM.li { className: styleProps.item.className, key: path }
      [ DOM.button
          { "aria-expanded": open
          , className: styleProps.row.className
          , onClick: handler_ (tree.toggle path)
          , style: depthStyle level
          , type: "button"
          }
          [ element chevronRightIcon
              { "aria-hidden": true
              , className:
                  ( StyleX.props [ styles.chevron, StyleX.conditional open styles.openChevron ]
                  ).className
              }
          , DOM.span styleProps.name name
          , if errors > 0
            then DOM.span
              { "aria-label": show errors <> " errors inside"
              , className: styleProps.errorDot.className
              }
              ([] :: Array JSX)
            else mempty
          ]
      , if open then folderContents tree (level + 1) folder else mempty
      ]

fileRow :: Tree -> Int -> TreeFile -> JSX
fileRow tree level file
  | tree.editing == Just file.path = renameRow tree level file
  | otherwise =
    let
      selected :: Boolean
      selected = isNothing (toMaybe tree.viewing) && toMaybe tree.active == Just file.path
    in
      DOM.li { className: itemClassName, key: file.path }
        [ DOM.button
            { "aria-current": if selected then "true" else "false"
            , className:
                ( StyleX.props [ styles.row, StyleX.conditional selected styles.activeRow ]
                ).className
            , onClick: handler_ (tree.actions.openFile file.path)
            , onDoubleClick: handler_ (tree.startRename file.path)
            , style: depthStyle level
            , title: file.path
            , type: "button"
            }
            [ element (iconFor file.name)
                { "aria-hidden": true, className: styleProps.icon.className }
            , DOM.span styleProps.name file.name
            , if file.errors > 0
              then countBadge styles.errorCount file.errors "errors"
              else if file.warnings > 0
              then countBadge styles.warningCount file.warnings "warnings"
              else mempty
            ]
        , DOM.span styleProps.actions
            [ DOM.button
                { "aria-label": "Rename " <> file.path
                , className: styleProps.action.className
                , onClick: handler_ (tree.startRename file.path)
                , title: "Rename"
                , type: "button"
                }
                (element pencilIcon { "aria-hidden": true })
            , if Array.length tree.files > 1
              then DOM.button
                { "aria-label": "Delete " <> file.path
                , className: styleProps.action.className
                , onClick: handler_ (tree.actions.deleteFile file.path)
                , title: "Delete"
                , type: "button"
                }
                (element trashIcon { "aria-hidden": true })
              else mempty
            ]
        ]

renameRow :: Tree -> Int -> TreeFile -> JSX
renameRow tree level file = DOM.li { className: itemClassName, key: file.path }
  [ DOM.createBuiltinElement_ "input"
      { "aria-label": "New path for " <> file.path
      , "aria-invalid": if isJust tree.problem then notNull true else null
      , className: styleProps.input.className
      , onBlur: handler_ tree.cancel
      , onChange: handler targetValue tree.editDraft
      , onKeyDown: handler key case _ of
          "Enter" -> tree.commit file.path
          "Escape" -> tree.cancel
          _ -> pure unit
      , ref: tree.input
      , spellCheck: false
      , style: depthStyle level
      , value: tree.draft
      }
  , case tree.problem, tree.anchor of
      Just message, Just anchor -> renameProblem message anchor
      _, _ -> mempty
  ]

renameProblem :: String -> { top :: Number, left :: Number } -> JSX
renameProblem message { top, left } = portalToBody
  ( DOM.span
      { className: styleProps.problem.className, role: "alert", style: DOM.css { top, left } }
      message
  )

countBadge :: StyleX.Style -> Int -> String -> JSX
countBadge tone count noun = DOM.span
  { "aria-label": show count <> " " <> noun
  , className: (StyleX.props [ styles.count, tone ]).className
  }
  (show count)

depthStyle :: Int -> DOM.CSS
depthStyle level = DOM.css { "--depth": level }

itemClassName :: String
itemClassName = (StyleX.props [ styles.item, StyleX.defaultMarker ]).className

targetValue :: EventFn SyntheticEvent String
targetValue = unsafeEventFn \event ->
  (unsafeCoerce event :: { target :: { value :: String } }).target.value

key :: EventFn SyntheticEvent String
key = unsafeEventFn \event -> (unsafeCoerce event :: { key :: String }).key
