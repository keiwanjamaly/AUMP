Needs["AUMP`"];

AUMPTestCase["arithmetic passes", {"core"},
    AUMPCHECK[1 + 1 == 2];
    AUMPREQUIREEqual[Head[{1, 2}], List];
]

AUMPTestCase["tagged slow test", {"slow"},
    AUMPCHECKEqual[2 * 3, 6];
]
