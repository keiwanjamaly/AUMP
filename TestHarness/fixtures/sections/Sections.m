Needs["AUMP`"];

AUMPTestCase["list behavior", {"sections"},
    prefix = "runs before each section";

    AUMPSection["empty",
        AUMPCHECKEqual[prefix, "runs before each section"];
        AUMPCHECKEqual[Length[{}], 0];
    ];

    AUMPSection["non-empty",
        AUMPCHECKEqual[prefix, "runs before each section"];
        AUMPCHECKEqual[Length[{1, 2}], 2];
    ];
]
