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
self-tests can run with the free Wolfram Engine Community Edition by setting the
`WOLFRAM_ENGINE_MATHPASS` repository secret to the contents of an activated
Wolfram Engine `mathpass` file. The workflow mounts that secret into Wolfram's
official `wolframresearch/wolframengine` Docker image.

To create the secret, activate the image once interactively as described by the
official Docker image documentation, print `$PasswordFile // FilePrint`, and
store the single printed `mathpass` line as `WOLFRAM_ENGINE_MATHPASS`.
Community Edition activation is node-locked and limited by Wolfram's terms, so
this uses one of the free activations associated with the Wolfram ID.

If no `WOLFRAM_ENGINE_MATHPASS` secret is configured, the workflow falls back to
a runner-provided `wolframscript`. If that runner needs an explicit kernel path,
set the `WOLFRAMSCRIPT_KERNELPATH` repository secret.
