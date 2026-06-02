#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  AUMP_BIN="$REPO_ROOT/AUMP/aump"
}

teardown() {
  if [ -n "${AUMP_TEST_TMPDIR:-}" ]; then
    rm -rf "$AUMP_TEST_TMPDIR"
  fi
}

kernel_available() {
  wolframscript -code '$VersionNumber' >/dev/null 2>&1
}

require_kernel() {
  if ! kernel_available; then
    skip "wolframscript cannot find a configured Wolfram kernel"
  fi
}

@test "wrapper reports an unconfigured Wolfram kernel clearly" {
  if kernel_available; then
    skip "kernel is configured"
  fi

  run "$AUMP_BIN" --path "$REPO_ROOT/TestHarness/fixtures/passing"
  [ "$status" -eq 127 ]
  [[ "$output" == *"no Wolfram kernel is configured"* || "$output" == *"wolframscript was not found"* ]]
}

@test "wrapper passes WolframScript entitlement to probe and runner" {
  AUMP_TEST_TMPDIR="$(mktemp -d)"
  fake_bin="$AUMP_TEST_TMPDIR/bin"
  mkdir -p "$fake_bin"

  cat >"$fake_bin/wolframscript" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$AUMP_FAKE_WOLFRAMSCRIPT_ARGS"
exit 0
EOF
  chmod +x "$fake_bin/wolframscript"

  run env \
    "AUMP_FAKE_WOLFRAMSCRIPT_ARGS=$AUMP_TEST_TMPDIR/args" \
    "WOLFRAMSCRIPT_ENTITLEMENTID=O-test-entitlement" \
    "PATH=$fake_bin:$PATH" \
    "$AUMP_BIN" --path "$REPO_ROOT/TestHarness/fixtures/passing"

  [ "$status" -eq 0 ]
  args="$(cat "$AUMP_TEST_TMPDIR/args")"
  [[ "$args" == *"-entitlement O-test-entitlement -code"* ]]
  [[ "$args" == *"-entitlement O-test-entitlement -script"* ]]
}

@test "passing suite exits zero" {
  require_kernel

  run "$AUMP_BIN" --path "$REPO_ROOT/TestHarness/fixtures/passing"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[pass] arithmetic passes"* ]]
  [[ "$output" == *"2 passed, 0 failed"* ]]
}

@test "CHECK failure is non-fatal" {
  require_kernel

  run "$AUMP_BIN" --path "$REPO_ROOT/TestHarness/fixtures/failing" --tag check --reporter json
  [ "$status" -ne 0 ]
  [[ "$output" == *'"Status":"failed"'* ]]
  [[ "$output" == *'"Assertions":2'* ]]
  [[ "$output" == *'"CHECK"'* ]]
}

@test "REQUIRE failure aborts the current leaf" {
  require_kernel

  run "$AUMP_BIN" --path "$REPO_ROOT/TestHarness/fixtures/failing" --tag require --reporter json
  [ "$status" -ne 0 ]
  [[ "$output" == *'"Assertions":1'* ]]
  [[ "$output" == *'"REQUIRE"'* ]]
}

@test "sections run as independent leaves" {
  require_kernel

  run "$AUMP_BIN" --path "$REPO_ROOT/TestHarness/fixtures/sections"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[pass] list behavior / empty"* ]]
  [[ "$output" == *"[pass] list behavior / non-empty"* ]]
  [[ "$output" == *"2 passed, 0 failed"* ]]
}

@test "tag filtering selects matching tests" {
  require_kernel

  run "$AUMP_BIN" --path "$REPO_ROOT/TestHarness/fixtures/passing" --tag slow
  [ "$status" -eq 0 ]
  [[ "$output" == *"[pass] tagged slow test"* ]]
  [[ "$output" != *"arithmetic passes"* ]]
}

@test "fresh kernels prevent global leakage between tests" {
  require_kernel

  run "$AUMP_BIN" --path "$REPO_ROOT/TestHarness/fixtures/isolation"
  [ "$status" -eq 0 ]
  [[ "$output" == *"2 passed, 0 failed"* ]]
}

@test "test output does not corrupt JSON reports" {
  require_kernel

  run "$AUMP_BIN" --path "$REPO_ROOT/TestHarness/fixtures/output" --reporter json
  [ "$status" -eq 0 ]
  [[ "$output" == *'"Output":"hello from test'* ]]
  [[ "$output" == *'"Summary"'* ]]
}

@test "syntax errors are reported as discovery failures" {
  require_kernel

  run "$AUMP_BIN" --path "$REPO_ROOT/TestHarness/fixtures/syntax_error"
  [ "$status" -eq 2 ]
  [[ "$output" == *"AUMP discovery failed"* ]]
}

@test "timeouts fail the selected test leaf" {
  require_kernel

  run "$AUMP_BIN" --path "$REPO_ROOT/TestHarness/fixtures/timeout" --timeout 1 --reporter json
  [ "$status" -ne 0 ]
  [[ "$output" == *'"Status":"timeout"'* ]]
}

@test "skipped tests exit zero and are reported" {
  require_kernel

  run "$AUMP_BIN" --path "$REPO_ROOT/TestHarness/fixtures/skip"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[skip] skipped dependency"* ]]
  [[ "$output" == *"1 skipped"* ]]
}

@test "standalone double dash is ignored" {
  require_kernel

  run "$AUMP_BIN" -- --path "$REPO_ROOT/TestHarness/fixtures/passing"
  [ "$status" -eq 0 ]
  [[ "$output" == *"2 passed, 0 failed"* ]]
}

@test "pattern and name filters select tests" {
  require_kernel

  run "$AUMP_BIN" --path "$REPO_ROOT/TestHarness/fixtures/discovery" --pattern Selected.m --list-tests
  [ "$status" -eq 0 ]
  [[ "$output" == *"selected by pattern"* ]]
  [[ "$output" != *"ignored by pattern"* ]]

  run "$AUMP_BIN" --path "$REPO_ROOT/TestHarness/fixtures/passing" --name slow
  [ "$status" -eq 0 ]
  [[ "$output" == *"[pass] tagged slow test"* ]]
  [[ "$output" != *"arithmetic passes"* ]]
}

@test "wl-path and init support package-style tests" {
  require_kernel

  run "$AUMP_BIN" \
    --path "$REPO_ROOT/TestHarness/fixtures/package/tests" \
    --wl-path "$REPO_ROOT/TestHarness/fixtures/package" \
    --init "$REPO_ROOT/TestHarness/fixtures/package/init.m"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[pass] package path and init are available"* ]]
}

@test "junit reporter and output file work" {
  require_kernel

  report_file="$(mktemp)"
  run "$AUMP_BIN" --path "$REPO_ROOT/TestHarness/fixtures/skip" --reporter junit --output "$report_file"
  [ "$status" -eq 0 ]
  [ -s "$report_file" ]
  report="$(cat "$report_file")"
  rm -f "$report_file"
  [[ "$output" == "" ]]
  [[ "$report" == *"<testsuite name=\"AUMP\""* ]]
  [[ "$report" == *"skipped=\"1\""* ]]
  [[ "$report" == *"<skipped message="* ]]
}

@test "output write failures are reported" {
  require_kernel

  AUMP_TEST_TMPDIR="$(mktemp -d)"
  output_path="$AUMP_TEST_TMPDIR/missing/report.xml"
  run "$AUMP_BIN" --path "$REPO_ROOT/TestHarness/fixtures/skip" --reporter junit --output "$output_path"
  [ "$status" -eq 2 ]
  [[ "$output" == *"AUMP: could not write report to"* ]]
}
