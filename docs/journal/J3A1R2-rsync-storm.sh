#!/bin/sh
set -eu

usage() {
    cat >&2 <<'EOF'
Usage:
  rsync-storm.sh -u TARGET_URI -n TESTS [-m BLOB_MIB] [-b BLOB_COUNT]

Options:
  -u TARGET_URI   rsync destination base URI (required)
                  example: rsync://petdrive.mockernel.local/drive
  -n TESTS        number of concurrent tests/jobs (required, > 0)
  -m BLOB_MIB     size of each blob file in MiB (default: 32)
  -b BLOB_COUNT   number of blob files per test directory (default: 1)
  -h              show this help

Example:
  ./rsync-storm.sh \
      -u rsync://petdrive.mockernel.local/drive \
      -n 6 \
      -m 32 \
      -b 1
EOF
    exit 2
}

is_posint() {
    case "${1-}" in
        ''|*[!0-9]*|0) return 1 ;;
        *) return 0 ;;
    esac
}

die() {
    printf '%s\n' "error: $*" >&2
    exit 1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

BLOB_MIB=32
BLOB_COUNT=1
TARGET_URI=
TESTS=
PIDS=
BASE=
STATUS=0

while getopts "u:n:m:b:h" opt; do
    case "$opt" in
        u) TARGET_URI=$OPTARG ;;
        n) TESTS=$OPTARG ;;
        m) BLOB_MIB=$OPTARG ;;
        b) BLOB_COUNT=$OPTARG ;;
        h) usage ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

[ $# -eq 0 ] || usage

[ -n "$TARGET_URI" ] || usage
[ -n "$TESTS" ] || usage

is_posint "$TESTS" || die "TESTS must be a positive integer"
is_posint "$BLOB_MIB" || die "BLOB_MIB must be a positive integer"
is_posint "$BLOB_COUNT" || die "BLOB_COUNT must be a positive integer"

require_cmd rsync
require_cmd dd
require_cmd mktemp

TARGET_URI=${TARGET_URI%/}
BASE=$(mktemp -d "${TMPDIR:-/tmp}/rsync-storm.XXXXXX")

cleanup() {
    trap - EXIT INT TERM

    for pid in $PIDS; do
        kill "$pid" 2>/dev/null || true
    done

    for pid in $PIDS; do
        wait "$pid" 2>/dev/null || true
    done

    rm -rf "$BASE"
}

trap cleanup EXIT
trap 'exit 130' INT TERM

printf 'base directory: %s\n' "$BASE"
printf 'target uri:     %s\n' "$TARGET_URI"
printf 'tests:          %s\n' "$TESTS"
printf 'blob mib:       %s\n' "$BLOB_MIB"
printf 'blob number:    %s\n' "$BLOB_COUNT"
printf '\n'

printf 'creating %s source directories under %s\n' "$TESTS" "$BASE"

i=1
while [ "$i" -le "$TESTS" ]; do
    d="$BASE/job-$i"
    mkdir -p "$d"

    j=1
    while [ "$j" -le "$BLOB_COUNT" ]; do
        dd if=/dev/zero of="$d/blob-$j.bin" bs=1048576 count="$BLOB_MIB" >/dev/null 2>&1
        j=$((j + 1))
    done

    printf 'hello from job %s\n' "$i" >"$d/file.txt"
    i=$((i + 1))
done

printf 'all source directories created\n'
printf 'launching rsync jobs\n'

i=1
while [ "$i" -le "$TESTS" ]; do
    (
        d="$BASE/job-$i"
        log="$BASE/job-$i.log"

        rsync -rtv --delete "$d"/ "$TARGET_URI/job-$i/" >"$log" 2>&1
    ) &
    PIDS="$PIDS $!"
    i=$((i + 1))
done

printf 'waiting for rsync jobs to finish\n'

set -- $PIDS
i=1
for pid do
    if wait "$pid"; then
        printf 'job-%s: ok\n' "$i"
    else
        rc=$?
        printf 'job-%s: failed (exit %s)\n' "$i" "$rc" >&2
        STATUS=1
    fi
    i=$((i + 1))
done

printf '\n===== per-job logs =====\n'

i=1
while [ "$i" -le "$TESTS" ]; do
    log="$BASE/job-$i.log"
    printf '\n--- job-%s ---\n' "$i"
    if [ -f "$log" ]; then
        cat "$log"
    else
        printf '%s\n' "(no log file)"
    fi
    i=$((i + 1))
done

printf '\nall done; cleaning up\n'
exit "$STATUS"