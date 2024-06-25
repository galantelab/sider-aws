#!/usr/bin/env bash

set -e

[[ -z "$1" ]] && { echo "No env passed" >&2; exit 1; }

tic="${2:-10}"

while true; do
	sleep "$tic"

	status=$(aws batch describe-compute-environments \
		--compute-environments="$1" \
		--query='computeEnvironments[0].[status,statusReason]')

	if [[ -z "$status" || "$status" == "null" ]]; then
		echo "Error. Maybe the env '$1' does not exist" >&2
		exit 1
	fi

	rc="$(jq -r '.[0]' <<< "$status")"
	msg="$(jq -r '.[1]' <<< "$status")"

	if [[ "$msg" != "null" ]]; then
		echo "$msg" >&2
	fi

	case "$rc" in
		VALID)   exit 0 ;;
		INVALID) exit 1 ;;
	esac
done
