Needs["AUMP`"];

AUMPTestCase["sets a global", {"isolation"},
    aumpLeakedGlobal = 42;
    AUMPCHECKEqual[aumpLeakedGlobal, 42];
]

AUMPTestCase["does not see previous global", {"isolation"},
    AUMPCHECK[! ValueQ[aumpLeakedGlobal]];
]
