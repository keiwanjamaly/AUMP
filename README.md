# AUMP

AUMP (Another Unmaintained Mathematica Package) is a small, vendored
Catch2-style test framework for Wolfram Language projects.

## Example

```wolfram
Needs["AUMP`"];

AUMPTestCase["basic arithmetic", {"core"},
    AUMPCHECK[1 + 1 == 2];
    AUMPREQUIREEqual[Head[{1, 2}], List];

    AUMPSection["empty list",
        AUMPCHECKEqual[Length[{}], 0];
    ];
]
```

## Running Tests

Vendor the `AUMP/` directory into a project and run:

```bash
AUMP/aump --path Tests
AUMP/aump --path Tests --tag core
AUMP/aump --path Tests --reporter json
AUMP/aump --path Tests --reporter junit --output test-results.xml
```

The `AUMP/aump` wrapper honors `WOLFRAMSCRIPT_KERNELPATH` and `WolframKernel`
when they are set. If they are not set, it looks for common Wolfram kernel
installations on macOS and Linux, including `/Applications/Wolfram.app`.

Each discovered test leaf runs in a fresh Wolfram kernel process. Sectioned
tests run once per section path. AUMP also creates a private temporary directory
for each test leaf and captures `Print` output and messages so JSON reports stay
parseable.

`AUMPCHECK` records a non-fatal failure and continues. `AUMPREQUIRE` records a
fatal failure and aborts the current test leaf.

Additional helpers cover common Wolfram package-test cases:

```wolfram
AUMPSKIP["optional dependency unavailable"];
AUMPAssume[Length[PacletFind["FunKit"]] > 0, "FunKit is not installed"];

AUMPCHECKAbort[functionThatShouldAbort[]];
AUMPCHECKMessage[Message[MyPackage::badarg], MyPackage::badarg];
AUMPCHECKNoMessages[quietExpression[]];

AUMPCHECKEquivalent[actual, expected, SameTest -> (TrueQ[FullSimplify[#1 == #2]] &)];
AUMPCHECKSimplifiesToZero[Sin[x]^2 + Cos[x]^2 - 1];
AUMPCHECKStringContainsAll[generatedCode, {"const double", "return"}];
AUMPCHECKStringEqualNormalized[generatedCode, expectedCode];
AUMPCHECKFileContent[fileName, expectedText];
```

For package-style projects, the runner can extend `$Path`, evaluate init files,
filter discovery, and list tests:

```bash
AUMP/aump --path Tests --wl-path Mathematica --init Tests/init.m
AUMP/aump --path Tests --pattern "*Tests.m" --name regulator
AUMP/aump --path Tests --list-tests
```

## Development Tests

AUMP uses two test layers. Wolfram-level framework semantics are covered by
AUMP self-tests under `Tests/`. CLI, worker isolation, timeout, reporter, and
wrapper behavior are covered from the outside with `bats-core`.

```bash
bats TestHarness/bats
```

The Bats tests skip Wolfram-dependent cases when no Wolfram kernel can be found.

GitHub Actions runs the Bats harness on every push and pull request. Wolfram
self-tests run in Wolfram's official `wolframresearch/wolframengine` Docker
image and require on-demand licensing through the repository secret
`WOLFRAMSCRIPT_ENTITLEMENTID`.

Create the entitlement from an authenticated Wolfram Language session with
`CreateLicenseEntitlement[...]`, copy `entitlement["EntitlementID"]`, and store
that `O-...` value as `WOLFRAMSCRIPT_ENTITLEMENTID`. The workflow fails if the
secret is missing or rejected by WolframScript.

Node-locked `mathpass` files are not used by the GitHub-hosted workflow because
they are tied to a stable machine identity and are rejected on fresh hosted
runners.
