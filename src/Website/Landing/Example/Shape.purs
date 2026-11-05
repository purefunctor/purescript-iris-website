module Website.Landing.Example.Shape where

import Prelude

data Shape = Circle Number | Rectangle Number Number

area :: Shape -> Number
area = case _ of
  Circle radius -> 3.14159 * radius * radius
  Rectangle width height -> width * height
