module Website.Jotai (Atom, UseAtom, atom, provider, useAtom) where

import Prelude

import Data.Tuple.Nested (type (/\), (/\))
import Effect (Effect)
import React.Basic (JSX, ReactComponent)
import React.Basic.Hooks (Hook, unsafeHook)

foreign import data Atom :: Type -> Type

foreign import data UseAtom :: Type -> Type -> Type

foreign import atom :: forall a. a -> Effect (Atom a)

foreign import provider :: ReactComponent { children :: JSX }

useAtom :: forall a. Atom a -> Hook (UseAtom a) (a /\ ((a -> a) -> Effect Unit))
useAtom atom' = unsafeHook (useAtomImpl (/\) atom')

foreign import useAtomImpl ::
  forall a. (forall x y. x -> y -> x /\ y) -> Atom a -> Effect (a /\ ((a -> a) -> Effect Unit))
