module Day1 where

import Parser
import Prelude
import Data.Array (catMaybes, cons, elemIndex, head)
import Data.Foldable (product)
import Data.Maybe (Maybe)
import Effect (Effect)
import Effect.Console (logShow)

inputParser :: Parser (Array Int)
inputParser = delimitedBy (stringP "\n") intParser

partA :: Int -> Array Int -> Maybe (Array Int)
partA target input =
  let
    subs :: Array Int
    subs = ((-) target) <$> input

    contains :: forall a. Eq a => a -> Array a -> Maybe a
    contains a haystack = const a <$> elemIndex a haystack

    needles :: Array Int
    needles = catMaybes $ (\sub -> contains sub input) <$> subs
  in
    (\x -> [ x, (target - x) ]) <$> head needles

partB :: Array Int -> Maybe (Array Int)
partB input =
  let
    targets = ((-) 2020) <$> input

    checkTarget :: Int -> Maybe (Array Int)
    checkTarget target = cons (2020 - target) <$> partA target input
  in
    head $ catMaybes $ checkTarget <$> targets

main :: Effect Unit
main = do
  expenses <- parsePuzzleInput "inputs/1.txt" inputParser
  logShow $ product <$> partA 2020 expenses
  logShow $ product <$> partB expenses
