#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AILANG_ROOT="${AILANG_ROOT:-${ROOT_DIR}/../AiLang}"
AILANG_BIN="${AILANG_BIN:-${AILANG_ROOT}/tools/ailang}"
AIVM_BIN="${AIVM_BIN:-${ROOT_DIR}/../AiVM/.tmp/aivm-c-build-native/aivm}"
FIXTURE="${ROOT_DIR}/packages/std-cli/tests/std_cli_contract.aos"
BUILD_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${BUILD_DIR}"
}
trap cleanup EXIT

"${AILANG_BIN}" build "${FIXTURE}" --out "${BUILD_DIR}" --no-cache >/dev/null

HELP_OUT="$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1" help greet)"
printf '%s\n' "${HELP_OUT}" | diff -u "${ROOT_DIR}/packages/std-cli/tests/golden/help-greet.txt" -
test "$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1" greet --help)" = "${HELP_OUT}"

ROOT_HELP="$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1" help)"
test "$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1" --help)" = "${ROOT_HELP}"
test "$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1")" = "${ROOT_HELP}"

VERSION_OUT="$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1" version)"
test "${VERSION_OUT}" = "sample 1.2.3"

set +e
EXECUTABLE_OUT="$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1" exec forwarded)"
EXECUTABLE_STATUS=$?
set -e
test "${EXECUTABLE_STATUS}" -eq 9
test "${EXECUTABLE_OUT}" = $'exec-error\nforwarded'

set +e
HANDLER_OUT="$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1" greet Todd --greeting Hi --loud)"
HANDLER_STATUS=$?
set -e
test "${HANDLER_STATUS}" -eq 7
test "${HANDLER_OUT}" = $'Todd:Hi\nLOUD'

set +e
ALIAS_OUT="$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1" greet Todd -g Welcome -l)"
ALIAS_STATUS=$?
set -e
test "${ALIAS_STATUS}" -eq 7
test "${ALIAS_OUT}" = $'Todd:Welcome\nLOUD'

set +e
MARKER_OUT="$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1" greet Todd -- --application-option)"
MARKER_STATUS=$?
set -e
test "${MARKER_STATUS}" -eq 7
test "${MARKER_OUT}" = 'Todd:hello'

set +e
UNKNOWN_OUT="$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1" greet Todd --unknown 2>&1)"
UNKNOWN_STATUS=$?
set -e
test "${UNKNOWN_STATUS}" -eq 2
printf '%s\n' "${UNKNOWN_OUT}" | rg -q '^CLI003: unknown option: --unknown$'

set +e
UNKNOWN_COMMAND_OUT="$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1" nope 2>&1)"
UNKNOWN_COMMAND_STATUS=$?
set -e
test "${UNKNOWN_COMMAND_STATUS}" -eq 2
printf '%s\n' "${UNKNOWN_COMMAND_OUT}" | rg -q '^CLI001: unknown command: nope$'

set +e
MISSING_VALUE_OUT="$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1" greet Todd --greeting 2>&1)"
MISSING_VALUE_STATUS=$?
set -e
test "${MISSING_VALUE_STATUS}" -eq 2
printf '%s\n' "${MISSING_VALUE_OUT}" | rg -q '^CLI004: missing value for option: --greeting$'

set +e
DUPLICATE_OUT="$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1" greet Todd --loud -l 2>&1)"
DUPLICATE_STATUS=$?
set -e
test "${DUPLICATE_STATUS}" -eq 2
printf '%s\n' "${DUPLICATE_OUT}" | rg -q '^CLI005: duplicate option: --loud$'

set +e
UNEXPECTED_OUT="$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1" greet Todd extra 2>&1)"
UNEXPECTED_STATUS=$?
set -e
test "${UNEXPECTED_STATUS}" -eq 2
printf '%s\n' "${UNEXPECTED_OUT}" | rg -q '^CLI007: unexpected argument: extra$'

set +e
MISSING_OUT="$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1" greet 2>&1)"
MISSING_STATUS=$?
set -e
test "${MISSING_STATUS}" -eq 2
printf '%s\n' "${MISSING_OUT}" | rg -q '^CLI006: missing required argument: name$'

echo "std-cli: PASS"
