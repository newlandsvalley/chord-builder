module Bass.Types where

import Prelude (negate)
import Data.Maybe (Maybe)

-- | a finger position on a string
-- | n < 0  : String is silent
-- | n == 0 : Open string is sounded
-- | N > 0  : string is fretted at this position
type FingerPosition = Int

-- | fingering is represented as an array of finger positions
type Fingering = Array FingerPosition

-- | we only export to PNG and JPG at the moment
data ExportFormat =
    PNG
  | JPG

-- | a fingered string
type FingeredString =
  { stringNumber :: Int
  , fretNumber  :: FingerPosition
  }

-- | the coordinates of a mouse click relative to the top left of the canvas
type MouseCoordinates =
  { x :: Number
  , y :: Number
  }

-- | parameters other than fingering that show up on the chord diagram
-- | and which are governed by HTML input boxes of some kind
type DiagramParameters =
  { name :: String             -- the chord name
  , firstFretOffset :: Int     -- which fret on the guitar does fret 1 represent
  , primaryString :: Maybe Int
  }

-- | an open string
open :: FingerPosition
open = 0

-- | a silent (unplayed) string
silent :: FingerPosition
silent = -1

-- | the MIME type for each export format
toMimeType :: ExportFormat -> String
toMimeType PNG = "image/png;base64"
toMimeType JPG = "image/jpeg"

-- | all the open strings
openStrings :: Fingering
openStrings =
  [open,open,open,open,open,open]

-- | and the chord that is therefore produced
openStringsChordName :: String
openStringsChordName =
  "Em11"