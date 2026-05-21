#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failed=0

check_descriptor() {
  local file="$1"
  local package_name
  local namespace_count
  local entry_count

  package_name="$(sed -n 's/^name = "\(.*\)"$/\1/p' "${file}" | head -n 1)"
  if [[ -z "${package_name}" ]]; then
    echo "package descriptor missing name: ${file}" >&2
    failed=1
    return
  fi

  if ! rg -q '^schema = "ailang\.package-source\.v1"$' "${file}"; then
    echo "package descriptor missing source schema: ${file}" >&2
    failed=1
  fi

  namespace_count="$(rg -c '^namespace = "' "${file}" || true)"
  entry_count="$(rg -c '^entry = "' "${file}" || true)"
  if [[ "${entry_count}" -gt 0 && "${namespace_count}" -ne "${entry_count}" ]]; then
    echo "library namespace count mismatch: ${file}" >&2
    failed=1
  fi

  while IFS= read -r namespace; do
    if [[ ! "${namespace}" =~ ^[a-z][a-z0-9]*([.][a-z][a-z0-9]*)+$ ]]; then
      echo "invalid dotted namespace '${namespace}' in ${file}" >&2
      failed=1
    fi
    if [[ "${namespace}" == *-* || "${namespace}" == *_* ]]; then
      echo "namespace must use dots, not dashes or underscores: ${namespace} in ${file}" >&2
      failed=1
    fi
  done < <(sed -n 's/^namespace = "\(.*\)"$/\1/p' "${file}")
}

while IFS= read -r descriptor; do
  check_descriptor "${descriptor}"
done < <(find "${ROOT_DIR}/packages" -name package.toml -print | sort)

if [[ "${failed}" -ne 0 ]]; then
  exit 1
fi

echo "package namespaces: PASS"
