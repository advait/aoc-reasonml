module Parser where

import Prelude
import Control.Alt (class Alt)
import Control.Alternative (class Alternative, (<|>))
import Control.Plus (class Plus)
import Data.Array (snoc)
import Data.Char.Unicode (isDigit)
import Data.Int (decimal, fromString, fromStringAs)
import Data.Maybe (Maybe(..))
import Data.String (CodePoint, codePointFromChar, drop, length, singleton, takeWhile, uncons)
import Data.String.CodeUnits (fromCharArray, toCharArray)
import Data.String.Unsafe (charAt)
import Data.Traversable (sequence)
import Undefined (undefined)

newtype Parser a
  = Parser (String -> Maybe ({ next :: String, p :: a }))

runParser :: forall a. Parser a -> (String -> Maybe ({ next :: String, p :: a }))
runParser (Parser p) = p

instance functorParser :: Functor Parser where
  map :: forall a b. (a -> b) -> Parser a -> Parser b
  map f (Parser parser) =
    Parser
      $ \input -> do
          { next, p } <- parser input
          Just { next, p: f p }

instance applyParser :: Apply Parser where
  apply :: forall a b. Parser (a -> b) -> Parser a -> Parser b
  -- | Runs the first parser, pipes the output into the second parser, and
  -- | applies the first parser's function to the second parser's result.
  apply (Parser parserFirst) (Parser parserSecond) =
    Parser
      $ \input -> do
          { next: next, p: parsedFirst } <- parserFirst input
          { next: next', p: parsedSecond } <- parserSecond next
          Just { next: next', p: parsedFirst parsedSecond }

instance applicativeParser :: Applicative Parser where
  -- | Returns a parser that always succeeds, proxying its input, and parsing a
  pure :: forall a. a -> Parser a
  pure a = Parser \input -> Just { next: input, p: a }

instance altParser :: Alt Parser where
  alt :: forall a. Parser a -> Parser a -> Parser a
  alt (Parser p1) (Parser p2) = Parser $ \input -> p1 input <|> p2 input

instance plusParser :: Plus Parser where
  empty :: forall a. Parser a
  empty = Parser $ const Nothing

instance alternativeParser :: Alternative Parser

{--| Only succeeds when input is empty. --}
eof :: Parser Unit
eof = Parser f
  where
  f "" = Just { next: "", p: unit }

  f _ = Nothing

-- | Parses a given constant `Char` `c`
charP :: Char -> Parser Char
charP c = Parser f
  where
  f s = do
    { head: head, tail: tail } <- uncons s
    if head == (codePointFromChar c) then
      Just $ { next: tail, p: c }
    else
      Nothing

-- | Parses a given constant `String` `s`.
stringP :: String -> Parser String
stringP s =
  let
    charArray = charP <$> toCharArray s
  in
    fromCharArray <$> sequence charArray

-- | Parser combinator that repeats the provided parser.
-- | Note that this parser will always succeed to account for empty lists.
repeated :: forall a. Parser a -> Parser (Array a)
repeated parser = Parser $ rec []
  where
  rec acc input = case runParser parser input of
    Nothing -> Just { next: input, p: acc }
    Just { next, p } -> rec (snoc acc p) next

-- | Parser combinator that parses items delimeted by spacers.
-- | Note that this parser will always succeed to account for empty lists.
delimitedBy :: forall s a. Parser s -> Parser a -> Parser (Array a)
delimitedBy (Parser spacer) (Parser item) = repeated pair
  where
  pair = (Parser item) <* (Parser spacer)

-- | Parses characters while the predicate holds true.
-- | Note that this parser will always succeed to account for empty lists.
takeWhileP :: (CodePoint -> Boolean) -> Parser String
takeWhileP pred =
  Parser \input ->
    let
      prefix = takeWhile pred input
    in
      Just { next: drop (length prefix) input, p: prefix }

-- | Parses characters while the predicate holds true.
-- | Note that this parser will always succeed to account for empty lists.
takeWhileCharP :: (Char -> Boolean) -> Parser String
takeWhileCharP pred =
  let
    charFromCodePoint codePoint = charAt 0 $ singleton codePoint
  in
    takeWhileP $ pred <<< charFromCodePoint

-- | Similar to bind but for Maybes within a Parser.
bindMaybe :: forall a b. Parser a -> (a -> Maybe b) -> Parser b
bindMaybe parser f =
  Parser \input -> do
    { next, p } <- runParser parser input
    b <- f p
    Just { next, p: b }

-- | Parses integers.
intParser :: Parser Int
intParser =
  let
    posIntParser = takeWhileCharP isDigit `bindMaybe` (fromStringAs decimal)

    negIntParser = (\i -> 0 - i) <$> (charP '-' *> posIntParser)
  in
    posIntParser <|> negIntParser