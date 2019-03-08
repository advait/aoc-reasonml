module Advent15 where

import qualified Data.Map    as Map
import qualified Data.Set    as Set
import qualified Debug.Trace as Trace

-- Represents an abstract node for pathfinding algorithms
class (Ord a, Show a) =>
      Node a
  where
  neighbors :: a -> [a] -- Returns neighbors in *sorted* order

-- (X, Y) cartesian coordinates
data Pos =
  Pos Int
      Int
  deriving (Eq)

-- Order positions according to "reading order": y first then x.
instance Ord Pos where
  compare (Pos x1 y1) (Pos x2 y2) = compare (y1, x1) (y2, x2)

instance Show Pos where
  show (Pos x y) = show (x, y)

-- Alternative compare function for [Node]/Paths that prefers shorter paths
-- before going into a node-by-node comparison if paths are equal length.
comparePath :: (Node a) => [a] -> [a] -> Ordering
comparePath a b
  | lenA < lenB = LT
  | lenA > lenB = GT
  | otherwise = compare a b
  where
    lenA = length a
    lenB = length b

-- Returns the shortest path from the first node to the second or Nothing
-- if we have exhaustively determined that no such path exists.
shortestPath :: (Node a) => a -> a -> Maybe [a]
shortestPath src dst = searchPathQueue dst startSeen startQueue
  where
    startSeen = Set.fromList [src] -- We keep track of which nodes we've already added to the queue
    startPath = [src] -- We greedily build up a Path from the src to the dst, node-by-node
    startQueue = [startPath] -- We work from a queue of Paths
    searchPathQueue :: (Node a) => a -> Set.Set a -> [[a]] -> Maybe [a]
    searchPathQueue _ _ [] = Nothing -- No more paths left in the queue, exhausted search space
    searchPathQueue dst seen (curPath:queue)
      | curNode == dst = Just curPath -- Reached our destination using curPath
      | otherwise = searchPathQueue dst newSeen newQueue
      where
        curNode = last curPath
        elligibleNeighbors = filter (`Set.notMember` seen) $ neighbors curNode
        newPaths = map (\n -> curPath ++ [n]) elligibleNeighbors
        newQueue = queue ++ newPaths
        newSeen = Set.union seen $ Set.fromList elligibleNeighbors

main :: IO ()
main = undefined
