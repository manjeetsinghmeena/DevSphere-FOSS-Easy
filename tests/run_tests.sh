#!/usr/bin/env bash
# =============================================================
#  DevSphere FOSS-Easy — Test Runner
#
#  Called by:
#    - pre-commit hook (local)
#    - fork-ci.yml     (fork push, participant's CI minutes)
#    - pr-checks.yml   (PR to main, authoritative)
#
#  Platform support:
#    Linux / macOS  — full support including TLE detection
#    Windows        — run inside Git Bash or WSL; TLE detection
#                     requires GNU coreutils (skipped otherwise)
#
#  Exit 0 = all tests passed
#  Exit 1 = compilation or test failure
# =============================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOLUTION="$ROOT/solution1.cpp"
BIN="$ROOT/solution_bin"
SAMPLES="$ROOT/samples"
TIMEOUT=40

# ── Cross-platform timeout helper ─────────────────────────────
# GNU timeout (Linux/WSL/CI): timeout 40s ./bin
# macOS with coreutils:       gtimeout 40s ./bin  (brew install coreutils)
# Git Bash on Windows:        no GNU timeout — run without time limit locally
#                             (CI always enforces the limit on Linux runners)
_run_timed() {
  local secs=$1; shift
  if command -v timeout &>/dev/null && timeout --version &>/dev/null 2>&1; then
    timeout "${secs}s" "$@"         # Linux / WSL / CI
  elif command -v gtimeout &>/dev/null; then
    gtimeout "${secs}s" "$@"        # macOS + brew coreutils
  else
    "$@"                            # Git Bash on Windows — no TLE locally
  fi
}

# ── Compile ───────────────────────────────────────────────────
echo "── Compile ──────────────────────────────────────────────"
if ! g++ -O2 -std=c++17 -o "$BIN" "$SOLUTION" 2>&1; then
  echo ""
  echo "FATAL: Compilation failed."
  exit 1
fi
echo "OK"
echo ""

# ── Run tests ─────────────────────────────────────────────────
echo "── Tests ────────────────────────────────────────────────"
PASS=0
FAIL=0

for in_file in "$SAMPLES"/in_*.txt; do
  # Guard: no matching files
  [[ -e "$in_file" ]] || { echo "No test inputs found in samples/"; break; }

  name=$(basename "$in_file" .txt | sed 's/^in_//')
  exp="$SAMPLES/out_${name}.txt"

  if [[ ! -f "$exp" ]]; then
    echo "SKIP  $name  (no expected output file out_${name}.txt)"
    continue
  fi

  if actual=$(_run_timed "$TIMEOUT" "$BIN" < "$in_file" 2>/dev/null); then
    # Compare output (strip trailing whitespace to tolerate CRLF vs LF differences)
    if diff <(printf '%s\n' "$actual" | sed 's/[[:space:]]*$//') \
            <(sed 's/[[:space:]]*$//' "$exp") > /dev/null 2>&1; then
      echo "PASS  $name"
      PASS=$((PASS + 1))
    else
      echo "FAIL  $name  — wrong output"
      echo "  expected (first 5 lines):"
      head -5 "$exp" | sed 's/^/    /'
      echo "  got (first 5 lines):"
      printf '%s\n' "$actual" | head -5 | sed 's/^/    /'
      FAIL=$((FAIL + 1))
    fi
  else
    ec=$?
    if [[ $ec -eq 124 ]]; then
      echo "FAIL  $name  — TLE (exceeded ${TIMEOUT}s)"
    else
      echo "FAIL  $name  — runtime error (exit $ec)"
    fi
    FAIL=$((FAIL + 1))
  fi
done

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────────"
echo "  Result: $PASS passed, $FAIL failed"
echo "────────────────────────────────────────────────────────"

[[ $PASS -eq 0 ]]
