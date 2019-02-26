module Main where

import qualified Data.IntSet as IntSet
import Debug.Trace
import Prelude

main :: IO ()
main = interact $ show . startProcess . parseInput

-- Parse the input strings with preceeding + or - values
intOfString :: String -> Int
intOfString "" = 0
intOfString s@(head:tail)
  | head == '+' = read tail::Int -- Need to manually parse '+'
  | otherwise = read s::Int

-- Processes stdin as a list of ints
parseInput :: String -> [Int]
parseInput s = map intOfString stringLines where
  stringLines = lines s

-- Processes the cycle returning the first duplicate sum
process :: [Int] -> Int -> IntSet.IntSet -> Int
process (head:tail) curSum seen =
  if IntSet.member curSum seen
  then curSum
  else process tail newSum  newSeen where
    newSeen = IntSet.insert curSum seen
    newSum = curSum + head

-- Kickoff process with proper initial values
startProcess :: [Int] -> Int
startProcess numbers = process infiniteNumbers 0 IntSet.empty where
  infiniteNumbers = cycle numbers
