module Problem2 exposing (..)

import Array exposing (Array)
import Computer exposing (Computer)
import List
import Util


{-| Returns a new computer with the given noun and verb replaced.
-}
withNewNounAndVerb : Int -> Int -> Computer -> Computer
withNewNounAndVerb noun verb comp =
    comp.memory |> Array.set 1 noun |> Array.set 2 verb |> Computer.withMem


{-| Solves Problem A.
-}
problemA : String -> Int
problemA input =
    input
        |> Computer.fromString
        |> Computer.execUntilHalt
        |> .memory
        |> Array.get 0
        |> Maybe.withDefault 0


{-| Solves Problem B.
-}
problemB : Int -> String -> Int
problemB desiredOutput input =
    let
        nounsAndVerbs =
            Util.permutations2 (List.range 0 99)

        execWithNounAndVerb noun verb =
            input
                |> Computer.fromString
                |> withNewNounAndVerb noun verb
                |> Computer.execUntilHalt
                |> .memory
                |> Array.get 0
                |> Maybe.withDefault 0

        rec : List ( Int, Int ) -> Int
        rec remainingNounsAndVerbs =
            case remainingNounsAndVerbs of
                [] ->
                    Debug.todo "Tried all pairs of nouns and verbs and failed"

                ( noun, verb ) :: tail ->
                    if execWithNounAndVerb noun verb == desiredOutput then
                        100 * noun + verb

                    else
                        rec tail
    in
    rec nounsAndVerbs
