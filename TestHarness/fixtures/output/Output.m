Needs["AUMP`"];

AUMPFixture::noise = "fixture message";

AUMPTestCase["captures output", {"output"},
    Print["hello from test"];
    Message[AUMPFixture::noise];
    AUMPCHECK[True];
]
