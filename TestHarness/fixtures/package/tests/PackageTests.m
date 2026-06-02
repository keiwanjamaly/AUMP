Needs["AUMP`"];
Needs["PackageUnderTest`"];

AUMPTestCase["package path and init are available", {"package"},
    AUMPCHECKEqual[PackageValue[], 42];
    AUMPCHECK[$AUMPInitLoaded];
]
