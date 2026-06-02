Needs["AUMP`"];

AUMPTestCase["runs too long", {"timeout"},
    Pause[5];
    AUMPCHECK[True];
]
