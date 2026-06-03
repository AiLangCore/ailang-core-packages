#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AILANG_BIN="${AILANG_BIN:-/Users/toddhenderson/RiderProjects/AiLangCore/AiLang/tools/ailang}"
GOLDEN_DIR="${ROOT_DIR}/packages/std-http/tests/golden"
TMP_DIR="${ROOT_DIR}/.tmp/std-http-golden"
REGISTRY_DIR="${TMP_DIR}/registry"
SOURCE_DIR="${TMP_DIR}/source"
PROJECT_DIR="${TMP_DIR}/project"

rm -rf "${TMP_DIR}"
mkdir -p "${REGISTRY_DIR}/packages" "${SOURCE_DIR}" "${PROJECT_DIR}/src"

cp -R "${ROOT_DIR}/packages" "${SOURCE_DIR}/packages"
(
  cd "${SOURCE_DIR}"
  git init --quiet
  git add packages
  git -c user.name=AiLangTest -c user.email=ailang-test@example.invalid commit --quiet -m source
)
SOURCE_COMMIT="$(git -C "${SOURCE_DIR}" rev-parse HEAD)"

cat > "${REGISTRY_DIR}/packages/std-app.toml" <<EOF
schema = "ailang.package.v1"
name = "std-app"
repo = "${SOURCE_DIR}"
packageRoot = "packages/std-app"
license = "MIT"
types = ["library"]
defaultVersion = "0.0.1-alpha.2"

[versions."0.0.1-alpha.2"]
ref = "HEAD"
commit = "${SOURCE_COMMIT}"
EOF

cat > "${REGISTRY_DIR}/packages/std-http.toml" <<EOF
schema = "ailang.package.v1"
name = "std-http"
repo = "${SOURCE_DIR}"
packageRoot = "packages/std-http"
license = "MIT"
types = ["library"]
defaultVersion = "0.0.1-alpha.7"

[versions."0.0.1-alpha.7"]
ref = "HEAD"
commit = "${SOURCE_COMMIT}"
EOF

cat > "${PROJECT_DIR}/project.aiproj" <<'EOF'
Program#p1 {
  Project#proj1(name="std-http-golden" entryFile="src/app.aos" entryExport="start" version="0.0.1-alpha.1") {
    Include#dep_http(name="std-http")
  }
}
EOF

AILANG_PACKAGE_REGISTRY="${REGISTRY_DIR}" "${AILANG_BIN}" package restore "${PROJECT_DIR}" >/dev/null
rm -f "${PROJECT_DIR}/project.aiproj"

for input in "${GOLDEN_DIR}"/stdlib_http_app.in.aos; do
  name="$(basename "${input}" .in.aos)"
  expected="${GOLDEN_DIR}/${name}.out.aos"
  actual="$(mktemp)"

  if [[ ! -f "${expected}" ]]; then
    echo "missing expected output: ${expected}" >&2
    rm -f "${actual}"
    exit 1
  fi

  cp "${input}" "${PROJECT_DIR}/src/app.aos"
  "${AILANG_BIN}" run "${PROJECT_DIR}/src/app.aos" > "${actual}"
  if ! diff -u "${expected}" "${actual}"; then
    echo "std-http golden mismatch: ${name}" >&2
    rm -f "${actual}"
    exit 1
  fi
  rm -f "${actual}"
done

rm -rf "${TMP_DIR}"

echo "std-http app golden: PASS"
