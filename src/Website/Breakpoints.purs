module Website.Breakpoints (breakpoints) where

import Iris.StyleX as StyleX

breakpoints = StyleX.defineConsts
  { upTo480: "@media (max-width: 480px)"
  , upTo600: "@media (max-width: 600px)"
  , upTo720: "@media (max-width: 720px)"
  , upTo800: "@media (max-width: 800px)"
  , upTo960: "@media (max-width: 960px)"
  , from960: "@media (min-width: 960px)"
  , upTo1160: "@media (max-width: 1160px)"
  , from641To800: "@media (min-width: 641px) and (max-width: 800px)"
  , above720To1160: "@media (720px < width <= 1160px)"
  , above800To1160: "@media (800px < width <= 1160px)"
  , above960To1160: "@media (960px < width <= 1160px)"
  }
