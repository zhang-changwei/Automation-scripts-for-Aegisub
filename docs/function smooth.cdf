(* Content-type: application/vnd.wolfram.cdf.text *)

(*** Wolfram CDF File ***)
(* http://www.wolfram.com/cdf *)

(* CreatedBy='Mathematica 11.3' *)

(***************************************************************************)
(*                                                                         *)
(*                                                                         *)
(*  Under the Wolfram FreeCDF terms of use, this file and its content are  *)
(*  bound by the Creative Commons BY-SA Attribution-ShareAlike license.    *)
(*                                                                         *)
(*        For additional information concerning CDF licensing, see:        *)
(*                                                                         *)
(*         www.wolfram.com/cdf/adopting-cdf/licensing-options.html         *)
(*                                                                         *)
(*                                                                         *)
(***************************************************************************)

(*CacheID: 234*)
(* Internal cache information:
NotebookFileLineBreakTest
NotebookFileLineBreakTest
NotebookDataPosition[      1088,         20]
NotebookDataLength[      4366,        112]
NotebookOptionsPosition[      4857,        108]
NotebookOutlinePosition[      5214,        124]
CellTagsIndexPosition[      5171,        121]
WindowFrame->Normal*)

(* Beginning of Notebook Content *)
Notebook[{

Cell[CellGroupData[{
Cell[BoxData[
 RowBox[{"Manipulate", "[", 
  RowBox[{
   RowBox[{"Plot", "[", 
    RowBox[{
     RowBox[{
      RowBox[{"(", 
       RowBox[{
        RowBox[{"(", 
         RowBox[{"1", "-", 
          RowBox[{"Cos", "[", 
           RowBox[{"2", " ", "Pi", " ", 
            RowBox[{"x", "^", "transverse"}]}], "]"}]}], ")"}], "/", "2"}], 
       ")"}], "^", "accel"}], ",", 
     RowBox[{"{", 
      RowBox[{"x", ",", "0", ",", "1"}], "}"}], ",", 
     RowBox[{"PlotRange", "\[Rule]", "Full"}]}], "]"}], ",", 
   RowBox[{"{", 
    RowBox[{"accel", ",", "0.2", ",", "5"}], "}"}], ",", 
   RowBox[{"{", 
    RowBox[{"transverse", ",", "0.2", ",", "5"}], "}"}]}], "]"}]], "Input",
 CellChangeTimes->{{3.8222056208721905`*^9, 3.822205624809825*^9}, {
  3.822205694257448*^9, 3.8222058266299243`*^9}, {3.8222058621542797`*^9, 
  3.822205913262742*^9}, {3.8222061005051966`*^9, 3.82220611120822*^9}, {
  3.82220617598127*^9, 3.822206178749225*^9}},
 CellLabel->"In[4]:=",ExpressionUUID->"4d1d1848-7c28-425a-be44-9659f20bc0f6"],

Cell[BoxData[
 TagBox[
  StyleBox[
   DynamicModuleBox[{$CellContext`accel$$ = 
    0.9999999999999989, $CellContext`transverse$$ = 1.0000000000000022`, 
    Typeset`show$$ = True, Typeset`bookmarkList$$ = {}, 
    Typeset`bookmarkMode$$ = "Menu", Typeset`animator$$, Typeset`animvar$$ = 
    1, Typeset`name$$ = "\"\:65e0\:6807\:9898\"", Typeset`specs$$ = {{
      Hold[$CellContext`accel$$], 0.2, 5}, {
      Hold[$CellContext`transverse$$], 0.2, 5}}, Typeset`size$$ = {
    360., {108., 113.}}, Typeset`update$$ = 0, Typeset`initDone$$, 
    Typeset`skipInitDone$$ = True, $CellContext`accel$23137$$ = 
    0, $CellContext`transverse$23138$$ = 0}, 
    DynamicBox[Manipulate`ManipulateBoxes[
     1, StandardForm, 
      "Variables" :> {$CellContext`accel$$ = 0.2, $CellContext`transverse$$ = 
        0.2}, "ControllerVariables" :> {
        Hold[$CellContext`accel$$, $CellContext`accel$23137$$, 0], 
        Hold[$CellContext`transverse$$, $CellContext`transverse$23138$$, 0]}, 
      "OtherVariables" :> {
       Typeset`show$$, Typeset`bookmarkList$$, Typeset`bookmarkMode$$, 
        Typeset`animator$$, Typeset`animvar$$, Typeset`name$$, 
        Typeset`specs$$, Typeset`size$$, Typeset`update$$, Typeset`initDone$$,
         Typeset`skipInitDone$$}, "Body" :> 
      Plot[((1 - Cos[(2 Pi) $CellContext`x^$CellContext`transverse$$])/
         2)^$CellContext`accel$$, {$CellContext`x, 0, 1}, PlotRange -> Full], 
      "Specifications" :> {{$CellContext`accel$$, 0.2, 
         5}, {$CellContext`transverse$$, 0.2, 5}}, "Options" :> {}, 
      "DefaultOptions" :> {}],
     ImageSizeCache->{411., {169., 175.}},
     SingleEvaluation->True],
    Deinitialization:>None,
    DynamicModuleValues:>{},
    SynchronousInitialization->True,
    UndoTrackedVariables:>{Typeset`show$$, Typeset`bookmarkMode$$},
    UnsavedVariables:>{Typeset`initDone$$},
    UntrackedVariables:>{Typeset`size$$}], "Manipulate",
   Deployed->True,
   StripOnInput->False],
  Manipulate`InterpretManipulate[1]]], "Output",
 CellChangeTimes->{{3.8222059072419353`*^9, 3.822205947044544*^9}, {
   3.822206116755273*^9, 3.8222061463927116`*^9}, 3.8222061812135763`*^9, {
   3.8222063024054003`*^9, 3.822206307810097*^9}, 3.8222065071056924`*^9},
 CellLabel->"Out[4]=",ExpressionUUID->"43484219-9e42-46c1-82bb-644d35be7436"]
}, Open  ]]
},
WindowSize->{759, 553},
WindowMargins->{{Automatic, 199}, {Automatic, 52}},
FrontEndVersion->"11.3 for Microsoft Windows (64-bit) (2018\:5e743\:670828\
\:65e5)",
StyleDefinitions->"Default.nb"
]
(* End of Notebook Content *)

(* Internal cache information *)
(*CellTagsOutline
CellTagsIndex->{}
*)
(*CellTagsIndex
CellTagsIndex->{}
*)
(*NotebookFileOutline
Notebook[{
Cell[CellGroupData[{
Cell[1510, 35, 1022, 25, 66, "Input",ExpressionUUID->"4d1d1848-7c28-425a-be44-9659f20bc0f6"],
Cell[2535, 62, 2306, 43, 363, "Output",ExpressionUUID->"43484219-9e42-46c1-82bb-644d35be7436"]
}, Open  ]]
}
]
*)

(* NotebookSignature #xpWEFOSb3USlDwFOJ3ZVQYP *)
