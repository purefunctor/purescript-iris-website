module Website.Landing.Example (source) where

-- | The example shown in the hero and the features section.
source :: String
source =
  """module Main where

import Prelude

import Effect (Effect)
import Effect.Console (log)

main :: Effect Unit
main = do
  log "Hello World"
  log "Hello Iris"
"""
