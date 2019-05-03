-- | draw the fretboard
module Guitar.Graphics
  ( canvasHeight
  , canvasWidth
  , titleDepth
  , displayChord
  , fingeredString
  ) where

import Prelude

import Color (Color, rgb, black, white)
import Data.Array (mapWithIndex, range)
import Data.Maybe (Maybe(..))
import Data.Foldable (foldl)
import Data.Int (floor, round, toNumber)
import Data.String.CodeUnits (dropRight, length)
import Graphics.Drawing (Drawing, circle, rectangle, filled, fillColor, text)
import Graphics.Drawing.Font (bold, light, font, sansSerif)
import Guitar.Types (DiagramParameters, Fingering, FingeredString, MouseCoordinates, open, silent)

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

titleDepth :: Number
titleDepth =
  35.0

nutyOffset:: Number
nutyOffset =
  70.0

nutxOffset:: Number
nutxOffset =
  cellSize * 1.5

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

-- | an open circle above the nut represents an open string
openString :: Int -> Drawing
openString stringNum =
  let
    outerRadius = 0.5 * fretDepth / 2.0
    innerRadius = outerRadius - 2.0
    xpos = nutxOffset + (toNumber stringNum * stringSeparation)
    ypos = nutyOffset - (outerRadius + 4.0)
  in
    filled
      (fillColor black)
      (circle xpos ypos outerRadius)
    <>
      filled
        (fillColor white)
        (circle xpos ypos innerRadius)

-- | a cross above the nut indicates a string which should not be played
silentString :: Int -> Drawing
silentString stringNum =
  let
    barLength = 0.25 * stringSeparation
    theFont = font sansSerif 26 bold
    xpos = nutxOffset +
           (toNumber stringNum * stringSeparation)
           - barLength
    ypos = nutyOffset - (nutDepth * 0.5)
  in
    text theFont xpos ypos (fillColor black) "x"


-- | draw a single finger on a string
-- | at the moment, silent strings have no canvas widget to represent them
-- | (such as a cross) they are thus marked by an absence..
finger :: Maybe FingeredString -> Int -> Int -> Drawing
finger  mBarre stringNum fretNum  =
  let
    radius = 0.7 * fretDepth / 2.0
    xpos = nutxOffset + (toNumber stringNum * stringSeparation)
    ypos = nutDepth + nutyOffset + (toNumber fretNum * fretDepth) - (radius + 2.0)
  in
    if
      (fretNum > fretCount) ||
      (stringNum < 0) || (stringNum >= stringCount)
    then
      mempty
    -- don't display the 0 or X against a barre'd string
    else if (stringIsBarred mBarre stringNum) && (fretNum <= open) then
      mempty
    else if (fretNum == open) then
      openString stringNum
    else if (fretNum == silent) then
      silentString stringNum
    else
      filled
        (fillColor black)
        (circle xpos ypos radius)


-- | draw the complete fingering
fingering :: Array Int -> Maybe FingeredString -> Drawing
fingering fingerSpec mBarre =
  foldl (<>) mempty $ mapWithIndex (finger mBarre) fingerSpec

-- | display the barré (if present)
barre :: Maybe FingeredString -> Drawing
barre mFingeredString =
  case mFingeredString of
    Just fs ->
      let
        xstart = nutxOffset + (toNumber fs.stringNumber * stringSeparation) - (stringSeparation / 4.0)
        xlen = toNumber (stringCount - fs.stringNumber- 1) * stringSeparation + (stringSeparation / 2.0)
        ystart = nutDepth + nutyOffset + (toNumber fs.fretNumber * fretDepth) - (fretDepth / 2.0)
        ylen = cellSize / 7.0
      in
        filled
          (fillColor black)
          (rectangle xstart ystart xlen ylen)
    _ ->
      mempty

-- | return true if the string is barréd
stringIsBarred :: Maybe FingeredString -> Int -> Boolean
stringIsBarred mFingeredString stringNum =
  case mFingeredString of
    Just fString ->
      fString.stringNumber <= stringNum
    _ ->
      false

-- | work out a fingered string from the mouse click coordinates
fingeredString :: MouseCoordinates -> FingeredString
fingeredString coords =
  let
    stringNumber =
      if coords.x < (nutxOffset / 2.0) then
        0
      else
        floor $ (coords.x - (nutxOffset / 2.0)) / stringSeparation

    fretNumber =
      if coords.y < (nutDepth + nutyOffset) then
        0
      else
        (floor $ (coords.y - (nutDepth + nutyOffset)) / fretDepth) + 1
    in
      { stringNumber : min stringNumber (stringCount - 1)
      , fretNumber  : min fretNumber fretCount
      }

-- | display the chord diagram title, but constrain it to live within
-- | the width of the nut, roughly centered
title :: String -> Drawing
title name =
  let
    theFont = font sansSerif 35 bold
    -- we seem to have space for at most 9 characters so truncate the name
    -- where necessary
    displayName =
      if (length name > 9) then
        dropRight (length name - 9) name
      else
        name
    -- rough heuristic for the width in pixels
    textWidth = (cellSize / 1.8) * (toNumber $ length displayName)
    -- work out the title x offset
    unsafeTitlexOffset = nutxOffset + (neckWidth / 2.0) - (textWidth / 2.0)
    -- but restrict it to start at the nut start for long strings
    titlexOffset = max unsafeTitlexOffset nutxOffset
  in
    text theFont titlexOffset titleDepth (fillColor black) displayName

-- | display the label of the first fret
firstFretLabel :: Int -> Drawing
firstFretLabel fretNo =
  if
    (fretNo < 1  || fretNo >= 10) then
      mempty
  else
    let
      theFont = font sansSerif 20 light
      displayNumber = show fretNo
      xpos = nutxOffset * 0.6
      ypos = nutDepth + nutyOffset + (fretDepth * 0.6)
  in
    text theFont xpos ypos (fillColor black) displayNumber


-- | display the enire choords hape described by the fingering
displayChord :: Fingering -> DiagramParameters -> Drawing
displayChord chord params =
  title params.name <>
        nut <>
        frets <>
        strings <>
        barre params.barre <>
        (fingering chord params.barre) <>
        firstFretLabel params.firstFretOffset
