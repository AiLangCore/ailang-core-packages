#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AILANG_BIN="${AILANG_BIN:-$(command -v ailang || true)}"
AIVM_BIN="${AIVM_BIN:-$(command -v aivm || true)}"
TMP_DIR="$(mktemp -d "${ROOT_DIR}/packages/std-json/.tmp-selfhost.XXXXXX")"

cleanup() {
  if [[ -z "${STD_JSON_TEST_KEEP:-}" ]]; then
    rm -rf "${TMP_DIR}"
  else
    echo "std-json test files retained at ${TMP_DIR}"
  fi
}
trap cleanup EXIT

if [[ ! -x "${AILANG_BIN}" ]]; then
  echo "AiLang launcher is not executable: ${AILANG_BIN}" >&2
  exit 1
fi
if [[ ! -x "${AIVM_BIN}" ]]; then
  echo "AiVM runtime is not executable: ${AIVM_BIN}" >&2
  exit 1
fi

mkdir -p "${TMP_DIR}/src/format"
cp "${ROOT_DIR}/packages/std-json/src/format/json.aos" \
  "${TMP_DIR}/src/format/json.aos"
cp "${ROOT_DIR}/packages/std-json/src/format/stringify.aos" \
  "${TMP_DIR}/src/format/stringify.aos"

cat >"${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="std-json-selfhost" entryFile="src/app.aos" entryExport="start" version="0.0.1") { }
}
AOS

cat >"${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Import(sdk="ailang" path="std/core.aos")
  Import(path="format/json.aos")
  Export(name=start)

  Let(name=start) {
    Fn(params=args) {
      Block {
        Call(target=sys.stdout.writeLine) {
          Call(target=std.json.stringify) {
            Map {
              Field(key="name") { Lit(value="Ada") }
              Field(key="ready") { Lit(value=true) }
            }
          }
        }
        Return { Lit(value=0) }
      }
    }
  }
}
AOS

"${AILANG_BIN}" build "${TMP_DIR}"
if [[ "$(basename "${AIVM_BIN}")" == "aivm-runtime" ]]; then
  actual="$("${AIVM_BIN}" run "${TMP_DIR}/bin/app.aibc1" --)"
else
  actual="$("${AIVM_BIN}" "${TMP_DIR}/bin/app.aibc1")"
fi
printf '%s\n' "${actual}" | grep -q '{"name":"Ada","ready":true}'

echo "std-json self-host build: PASS"
