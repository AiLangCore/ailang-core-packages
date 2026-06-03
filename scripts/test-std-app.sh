#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AILANG_BIN="${AILANG_BIN:-/Users/toddhenderson/RiderProjects/AiLangCore/AiLang/tools/ailang}"
GOLDEN_DIR="${ROOT_DIR}/packages/std-app/tests/golden"

for input in "${GOLDEN_DIR}"/*.in.aos; do
  name="$(basename "${input}" .in.aos)"
  expected="${GOLDEN_DIR}/${name}.out.aos"
  actual="$(mktemp)"

  if [[ ! -f "${expected}" ]]; then
    echo "missing expected output: ${expected}" >&2
    rm -f "${actual}"
    exit 1
  fi

  "${AILANG_BIN}" run "${input}" > "${actual}"
  if ! diff -u "${expected}" "${actual}"; then
    echo "std-app golden mismatch: ${name}" >&2
    rm -f "${actual}"
    exit 1
  fi
  rm -f "${actual}"
done

echo "std-app golden: PASS"
