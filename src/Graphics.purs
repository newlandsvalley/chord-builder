-- | draw the fretboard
module Graphics (canvasHeight, canvasWidth, chordDisplay) where

import Prelude

import Color (Color, rgb, black)
import Data.Array (mapWithIndex, range)
import Data.Foldable (foldl)
import Data.Int (round, toNumber)
import Graphics.Drawing (Drawing, circle, rectangle, filled, fillColor)

gray :: Color
gray = rgb 160 160 160

canvasWidth :: Int
canvasWidth =
  round $ neckWidth + (2.0 * nutxOffset)

canvasHeight :: Int
canvasHeight =
  round $ nutDepth + nutyOffset + stringLength + cellSize

-- | this is the basic size of a cell bounded by 2 frets and 2 strings
-- | and thus represents a unit of scalability
cellSize :: Number
cellSize =
  36.0

neckWidth :: Number
neckWidth =
  stringSeparation * toNumber (stringCount -1)

nutDepth :: Number
nutDepth =
  cellSize / 3.0

nutyOffset:: Number
nutyOffset =
  50.0

nutxOffset:: Number
nutxOffset =
  cellSize

fretDepth :: Number
fretDepth =
  cellSize

fretWidth :: Number
fretWidth =
  2.0

fretCount :: Int
fretCount =
  6

stringCount :: Int
stringCount =
  6

stringSeparation :: Number
stringSeparation =
  cellSize

stringLength :: Number
stringLength =
  (toNumber fretCount) * fretDepth

stringWidth :: Number
stringWidth =
  2.0

nut :: Drawing
nut =
  filled
    (fillColor gray)
    (rectangle nutxOffset nutyOffset (neckWidth + stringWidth) nutDepth)

fret :: Int -> Drawing
fret n =
  let
    fretyOffset =  toNumber n  * fretDepth
  in
    filled
      (fillColor black)
      (rectangle nutxOffset (nutDepth + nutyOffset + fretyOffset) neckWidth fretWidth)

-- draw thw frets
frets :: Drawing
frets =
  let
    fretNums = range 1 fretCount
    f :: Drawing -> Int -> Drawing
    f acc n = acc <> (fret n)
  in
    foldl f mempty fretNums

aString :: Int -> Drawing
aString n =
  let
    xOffset =  nutxOffset + toNumber n  * stringSeparation
    yOffset = nutDepth + nutyOffset
  in
    filled
      (fillColor black)
      (rectangle xOffset (nutDepth + nutyOffset) stringWidth stringLength)

-- | draw the strings
strings :: Drawing
strings =
  let
    stringNums = range 0 (stringCount -1)
    f :: Drawing -> Int -> Drawing
    f acc n = acc <> (aString n)
  in
    foldl f mempty stringNums

-- | draw a single finger on a string
finger :: Int -> Int -> Drawing
finger stringNum fretNum  =
  let
    radius = 0.7 * fretDepth / 2.0
    xpos = nutxOffset + (toNumber stringNum * stringSeparation)
    ypos = nutDepth + nutyOffset + (toNumber fretNum * fretDepth) - (radius + 2.0)
  in
    if
      (fretNum < 1) || (fretNum >= fretCount) ||
      (stringNum < 0) || (stringNum >= stringCount)
    then
      mempty
    else
      filled
        (fillColor black)
        (circle xpos ypos radius)

-- | draw the complete fingering
fingering :: Array Int -> Drawing
fingering fingerSpec =
  foldl (<>) mempty $ mapWithIndex finger fingerSpec

chordDisplay :: Drawing
chordDisplay =
  nut <> frets <> strings <> (fingering dChord)

dChord :: Array Int
dChord =
  [2,0,0,2,3,2]
