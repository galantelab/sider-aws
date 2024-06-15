#!/usr/bin/env bash

[[ -z "$1" ]] && { echo "No env passed" >&2; exit 1; }

tic="${2:-10}"
tfile="$(mktemp)"

trap 'rm -f "$tfile"' EXIT

while true; do
	sleep "$tic"

	aws batch describe-compute-environments \
		--compute-environments="$1" \
		--no-paginate \
		--query='computeEnvironments[0].[status,statusReason]' \
		> "$tfile"

	if [[ "$(cat $tfile)" == "null" ]]; then
		echo "Error. Maybe the env '$1' does not exist" >&2
		exit 1
	fi

	rc="$(jq -r '.[0]' "$tfile")"
	msg="$(jq -r '.[1]' "$tfile")"

	echo "$msg" >&2

	case "$rc" in
		VALID)   exit 0 ;;
		INVALID) exit 1 ;;
	esac
done
