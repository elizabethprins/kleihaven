module Ui.Icons.Close exposing (view)

import Svg exposing (Svg, line, svg)
import Svg.Attributes exposing (fill, height, stroke, strokeLinecap, strokeLinejoin, strokeWidth, viewBox, width, x1, x2, y1, y2)


view : Svg msg
view =
    svg
        [ viewBox "0 0 24 24"
        , width "24"
        , height "24"
        , fill "none"
        , stroke "currentColor"
        , strokeWidth "2"
        , strokeLinecap "round"
        , strokeLinejoin "round"
        ]
        [ line [ x1 "18", y1 "6", x2 "6", y2 "18" ] []
        , line [ x1 "6", y1 "6", x2 "18", y2 "18" ] []
        ]
