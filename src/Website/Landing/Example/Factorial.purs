module Website.Landing.Example.Factorial where

import Prelude

factorial :: Int -> Int -> Int
factorial 0 acc = acc
factorial n acc = factorial (n - 1) (acc * n)
