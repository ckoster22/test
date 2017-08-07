module Runner.String.Format exposing (format)

import Diff exposing (Change(..))
import Test.Runner.Failure exposing (InvalidReason(BadDescription), Reason(..))


format : String -> Reason -> String
format description reason =
    case reason of
        Custom ->
            description

        Equality expected actual ->
            equalityToString { operation = description, expected = expected, actual = actual }

        Comparison first second ->
            verticalBar description first second

        TODO ->
            description

        Invalid BadDescription ->
            if description == "" then
                "The empty string is not a valid test description."
            else
                "This is an invalid test description: " ++ description

        Invalid _ ->
            description

        ListDiff expected actual ->
            listDiffToString 0
                description
                { expected = expected
                , actual = actual
                }
                { originalExpected = expected
                , originalActual = actual
                }

        CollectionDiff { expected, actual, extra, missing } ->
            let
                extraStr =
                    if List.isEmpty extra then
                        ""
                    else
                        "\nThese keys are extra: "
                            ++ (extra |> String.join ", " |> (\d -> "[ " ++ d ++ " ]"))

                missingStr =
                    if List.isEmpty missing then
                        ""
                    else
                        "\nThese keys are missing: "
                            ++ (missing |> String.join ", " |> (\d -> "[ " ++ d ++ " ]"))
            in
            String.join ""
                [ verticalBar description expected actual
                , "\n"
                , extraStr
                , missingStr
                ]


verticalBar : String -> String -> String -> String
verticalBar comparison expected actual =
    [ actual
    , "╵"
    , "│ " ++ comparison
    , "╷"
    , expected
    ]
        |> String.join "\n"


listDiffToString :
    Int
    -> String
    -> { expected : List String, actual : List String }
    -> { originalExpected : List String, originalActual : List String }
    -> String
listDiffToString index description { expected, actual } originals =
    case ( expected, actual ) of
        ( [], [] ) ->
            -- This should never happen! Recurse into oblivion.
            listDiffToString (index + 1)
                description
                { expected = [], actual = [] }
                originals

        ( first :: _, [] ) ->
            verticalBar (description ++ " was shorter than")
                (toString originals.originalExpected)
                (toString originals.originalActual)

        ( [], first :: _ ) ->
            verticalBar (description ++ " was longer than")
                (toString originals.originalExpected)
                (toString originals.originalActual)

        ( firstExpected :: restExpected, firstActual :: restActual ) ->
            if firstExpected == firstActual then
                -- They're still the same so far; keep going.
                listDiffToString (index + 1)
                    description
                    { expected = restExpected
                    , actual = restActual
                    }
                    originals
            else
                -- We found elements that differ; fail!
                String.join ""
                    [ verticalBar description
                        (toString originals.originalExpected)
                        (toString originals.originalActual)
                    , "\n\nThe first diff is at index "
                    , toString index
                    , ": it was `"
                    , firstActual
                    , "`, but `"
                    , firstExpected
                    , "` was expected."
                    ]


equalityToString : { operation : String, expected : String, actual : String } -> String
equalityToString { operation, expected, actual } =
    let
        formattedExpected =
            Diff.diff (String.toList expected) (String.toList actual)
                |> List.concatMap formatExpectedChange
                |> String.join ""

        formattedActual =
            Diff.diff (String.toList actual) (String.toList expected)
                |> List.concatMap formatActualChange
                |> String.join ""
    in
    verticalBar operation formattedExpected formattedActual


formatExpectedChange : Change Char -> List String
formatExpectedChange diff =
    case diff of
        Added char ->
            []

        Removed char ->
            [ "\x1B[43m", String.fromChar char, "\x1B[49m" ]

        NoChange char ->
            [ String.fromChar char ]


formatActualChange : Change Char -> List String
formatActualChange diff =
    case diff of
        Added char ->
            []

        Removed char ->
            [ "\x1B[43m", String.fromChar char, "\x1B[49m" ]

        NoChange char ->
            [ String.fromChar char ]
