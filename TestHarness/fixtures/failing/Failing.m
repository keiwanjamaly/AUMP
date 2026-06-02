Needs["AUMP`"];

AUMPTestCase["check continues after failure", {"check"},
    AUMPCHECK[False];
    AUMPCHECK[True];
]

AUMPTestCase["require stops after failure", {"require"},
    AUMPREQUIRE[False];
    AUMPCHECK[False];
]
