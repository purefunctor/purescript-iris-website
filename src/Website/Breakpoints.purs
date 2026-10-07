module Website.Breakpoints (breakpoints) where

import Iris.StyleX as StyleX

-- Keep the bounds explicit: these queries overlap and are not device categories.
breakpoints =
  StyleX.defineConsts
    { upTo480: "@media (max-width: 480px)"
    , upTo600: "@media (max-width: 600px)"
    , upTo720: "@media (max-width: 720px)"
    , upTo800: "@media (max-width: 800px)"
    , upTo960: "@media (max-width: 960px)"
    , from960: "@media (min-width: 960px)"
    , upTo1160: "@media (max-width: 1160px)"
    , from641To800: "@media (min-width: 641px) and (max-width: 800px)"
    -- Imported queries bypass StyleX's overlap normalization. Keep cases for one property
    -- disjoint, with a strict bound rather than a fractional min-width browsers may round.
    , above800To1160: "@media (800px < width <= 1160px)"
    , above960To1160: "@media (960px < width <= 1160px)"
    }
