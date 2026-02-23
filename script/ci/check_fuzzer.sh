#!/usr/bin/env bash
set -euo pipefail

fuzzer="${1:-}"
if [[ -z "${fuzzer}" ]]; then
  echo "Usage: $0 <foundry|echidna|medusa>" >&2
  exit 2
fi

timeout_seconds="${FUZZER_TIMEOUT_SECONDS:-120}"
output_dir="${FUZZER_OUTPUT_DIR:-./fuzzer-logs}"
mkdir -p "${output_dir}"
log_file="${output_dir}/${fuzzer}.log"

timeout_cmd=()
if command -v timeout >/dev/null 2>&1; then
  timeout_cmd=(timeout -k 5s "${timeout_seconds}s")
elif command -v gtimeout >/dev/null 2>&1; then
  timeout_cmd=(gtimeout -k 5s "${timeout_seconds}s")
fi

search_log() {
  local pattern="$1"
  local file="$2"
  if command -v rg >/dev/null 2>&1; then
    rg -n "${pattern}" "${file}" >/dev/null 2>&1
  else
    grep -E -n "${pattern}" "${file}" >/dev/null 2>&1
  fi
}

run_with_log() {
  local -a cmd=("$@")
  set +e
  if [[ ${#timeout_cmd[@]} -gt 0 ]]; then
    "${timeout_cmd[@]}" "${cmd[@]}" 2>&1 | tee "${log_file}"
    local status=${PIPESTATUS[0]}
  else
    "${cmd[@]}" 2>&1 | tee "${log_file}"
    local status=${PIPESTATUS[0]}
  fi
  set -e
  return "${status}"
}

patterns=()
case "${fuzzer}" in
  foundry)
    patterns=(
      "invariant_number_is_small\\(\\)"
      "invariant_number_change_requires_sequence\\(\\)"
      "invariant_counter_increment\\(\\)"
      "panic: assertion failed \\(0x01\\)"
    )
    run_with_log forge test \
      --match-contract CryticToFoundry \
      --match-test "invariant_" \
      --match-path test/recon/CryticToFoundry.sol \
      -vvv || true
    ;;
  echidna)
    patterns=("invariant_number_is_small\\(\\).*falsified" "counter_increment\\(\\).*falsified")
    run_with_log echidna test/recon/CryticTester.sol --contract CryticTester --config echidna.yaml --format text --timeout "${timeout_seconds}" --workers 4 || true
    ;;
  medusa)
    patterns=("\\[FAILED\\].*invariant_number_is_small" "\\[FAILED\\].*counter_increment")
    run_with_log medusa fuzz --config medusa.json || true
    ;;
  *)
    echo "Unknown fuzzer: ${fuzzer}" >&2
    exit 2
    ;;
esac

missing=0
for pattern in "${patterns[@]}"; do
  if ! search_log "${pattern}" "${log_file}"; then
    echo "Expected issue not found in ${fuzzer} output: ${pattern}" >&2
    missing=1
  fi
done

if [[ "${missing}" -ne 0 ]]; then
  echo "Fuzzer output saved to ${log_file}" >&2
  exit 1
fi

echo "Detected expected issues for ${fuzzer}."
