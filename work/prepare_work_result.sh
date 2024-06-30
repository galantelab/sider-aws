#!/usr/bin/env bash

set -e

[[ $# -lt 3 ]] && { echo "Usage: $0 <S3_BUCKET> <INPUT_DIR> <OUTPUT_DIR>"; exit; }

S3_BUCKET="$1"
INPUT_DIR="$2"
OUTPUT_DIR="$3"

mapfile -t BATCH_FILES < <(find "$INPUT_DIR" -name "batch*.json")

mkdir -p "$OUTPUT_DIR"

for batch_file in "${BATCH_FILES[@]}"; do
	echo "Prepare result for '$batch_file'" >&2

	job_name=$(jq -r '.jobName' "$batch_file")
	job_id=$(jq -r '.jobId' "$batch_file")

	output_dir="$OUTPUT_DIR/${job_name/batch/}"

	mkdir -p "$output_dir"

	cp "$batch_file" "$output_dir/batch.json"
	cp "${batch_file%/*}/MANIFEST.$job_name" "$output_dir/MANIFEST"

	aws batch describe-jobs --jobs="$job_id" > "$output_dir/job.json"
	aws s3 cp --recursive "$S3_BUCKET/$job_id" "$output_dir"
done
