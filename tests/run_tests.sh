#!/usr/bin/env bash
# ABOUTME: Test runner with assert helpers sourced by all test_*.sh files
# ABOUTME: Accumulates PASS/FAIL counts across sourced test files

set -euo pipefail

PASS=0
FAIL=0
export DB_PATH="$(dirname "$0")/../db/test.db"

assert_equals() {
  local expected="$1" actual="$2" msg="${3:-assert_equals}"
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $msg"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $msg"
    echo "    expected: [$expected]"
    echo "    actual:   [$actual]"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local needle="$1" haystack="$2" msg="${3:-assert_contains}"
  if echo "$haystack" | grep -qF "$needle"; then
    echo "  PASS: $msg"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $msg"
    echo "    expected to find: [$needle]"
    FAIL=$((FAIL + 1))
  fi
}

export -f assert_equals
export -f assert_contains

for test_file in "$(dirname "$0")"/test_*.sh; do
  echo ""
  echo "=== $(basename "$test_file") ==="
  # shellcheck source=/dev/null
  source "$test_file"
done

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
