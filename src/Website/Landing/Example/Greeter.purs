module Website.Landing.Example.Greeter where

import Prelude

import Effect (Effect)
import Effect.Console as Console

foreign import ask :: String -> Effect String

main :: Effect Unit
main = do
  name <- ask "What is your name?"
  Console.log ("Hello, " <> name <> "!")
