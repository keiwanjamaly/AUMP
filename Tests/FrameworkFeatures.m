Needs["AUMP`"];

AUMPSelfTest::noise = "noise";

AUMPMakeLeaf[name_String, body_] := <|
    "Name" -> name,
    "Tags" -> {},
    "Body" -> body,
    "File" -> "self-test",
    "Index" -> 1,
    "FileIndex" -> 1
|>;

AUMPRunBody[name_String, body_] := AUMPRunLeaf[AUMPMakeLeaf[name, body], {}, <||>];

AUMPTestCase["skip and assumption status", {"self"},
    result = AUMPRunBody["skip", HoldComplete[AUMPSKIP["missing dependency"]]];
    AUMPCHECKEqual[result["Status"], "skipped"];
    AUMPCHECKEqual[result["SkipReason"], "missing dependency"];

    result = AUMPRunBody["assume", HoldComplete[AUMPAssume[False, "not configured"]]];
    AUMPCHECKEqual[result["Status"], "skipped"];
];

AUMPTestCase["abort assertions", {"self"},
    result = AUMPRunBody["check abort passes", HoldComplete[AUMPCHECKAbort[Abort[]]]];
    AUMPCHECKEqual[result["Status"], "passed"];

    result = AUMPRunBody["check abort fails", HoldComplete[AUMPCHECKAbort[1 + 1]]];
    AUMPCHECKEqual[result["Status"], "failed"];
    AUMPCHECKEqual[result["Failures"][[1, "Kind"]], "CHECKAbort"];

    result = AUMPRunBody["require abort fails", HoldComplete[AUMPREQUIREAbort[1 + 1]; AUMPCHECK[False]]];
    AUMPCHECKEqual[result["Assertions"], 1];
];

AUMPTestCase["message assertions", {"self"},
    result = AUMPRunBody["expected message", HoldComplete[AUMPCHECKMessage[Message[AUMPSelfTest::noise], AUMPSelfTest::noise]]];
    AUMPCHECKEqual[result["Status"], "passed"];

    result = AUMPRunBody["no messages", HoldComplete[AUMPCHECKNoMessages[1 + 1]]];
    AUMPCHECKEqual[result["Status"], "passed"];

    result = AUMPRunBody["unexpected message", HoldComplete[AUMPCHECKNoMessages[Message[AUMPSelfTest::noise]]]];
    AUMPCHECKEqual[result["Status"], "failed"];
    AUMPCHECKEqual[result["Failures"][[1, "Kind"]], "CHECKNoMessages"];
];

AUMPTestCase["symbolic and string assertions", {"self"},
    result = AUMPRunBody["equivalent", HoldComplete[
        AUMPCHECKEquivalent[(x + 1)^2, x^2 + 2 x + 1, SameTest -> (TrueQ[FullSimplify[#1 == #2]] &)];
        AUMPCHECKSimplifiesToZero[Sin[x]^2 + Cos[x]^2 - 1];
        AUMPCHECKStringContainsAll["const double cospq = cos1;", {"const double", "cospq"}];
        AUMPCHECKStringEqualNormalized["const  double\nx = 1;", "const double x = 1;"];
    ]];
    AUMPCHECKEqual[result["Status"], "passed"];
    AUMPCHECKEqual[result["Assertions"], 4];
];

AUMPTestCase["file and temp helpers", {"self"},
    result = AUMPRunBody["file content", HoldComplete[
        AUMPWithTempDirectory[
            file = FileNameJoin[{AUMPTestTempDirectory[], "generated.txt"}];
            Export[file, "generated code", "Text"];
            AUMPCHECKFileContent[file, "generated code"];
        ];
    ]];
    AUMPCHECKEqual[result["Status"], "passed"];
];
