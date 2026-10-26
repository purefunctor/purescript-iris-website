module Website.Landing.Example (source) where

source :: String
source = """module Main where

import Prelude

import Effect (Effect)
import Effect.Console (log)

main :: Effect Unit
main = do
  log "Hello World"
  log "Hello Iris"
"""
