#!/usr/bin/env bash
# Let's rock ;)

set -o errexit
set -o pipefail
set -o nounset

readonly PROGNAME="worker"

say() {
	echo -e "[${BASH_LINENO[0]} $PROGNAME] $@" >&2
}

die() {
	echo -e "[${BASH_LINENO[0]} $PROGNAME] $@" >&2
	exit 1
}

usage() {
	local name_space=$(echo "Usage: $PROGNAME" | tr '[:alnum:].:' ' ')
	local acm=0
	local key

	echo -ne "\nUsage: $PROGNAME [-h|--help]"

	for key in "${!OPTIONS[@]}"; do
		if (( ++acm % 2 )); then
			echo -ne " [$key=${OPTIONS[$key]}]"
		else
			echo -ne "\n$name_space [$key=${OPTIONS[$key]}]"
		fi
	done

	echo -ne "\n\n"
}

if [[ -z "${AWS_BATCH_JOB_ID:-}" ]]; then
	die "This script is meant to run on AWS Batch"
fi

# Read only values
readonly OUTPUT_DIR="$AWS_BATCH_JOB_ID"
readonly SIDER_DB_DIR="sider"
readonly GDC_DIR="download"
readonly REFERENCE_DIR="reference"

# Mandatory values
S3_OUTPUT_BUCKET=
S3_GENOME_FILE=
S3_ANNOTATION_FILE=
S3_MANIFEST_FILE=
S3_GDC_TOKEN=

# Lazy values - internal definition
GENOME_FILE=
ANNOTATION_FILE=
MANIFEST_FILE=
GDC_TOKEN=

# Default values for sideRETRO
SIDER_PREFIX="sider"
SIDER_THREADS=1
SIDER_EPSILON=500
SIDER_MIN_PTS=10
SIDER_CACHE=200000
SIDER_MAX_DIST=15000
SIDER_EXON_FRAC=0.25
SIDER_ALIGN_FRAC=0.25
SIDER_QUALITY=20
SIDER_GENOTYPE=5

# Default values for gdc-client
GDC_JOBS=1

# All options available
declare -A OPTIONS=(
	[--s3-output-bucket]=STR
	[--s3-genome-file]=STR
	[--s3-annotation-file]=STR
	[--s3-manifest-file]=STR
	[--s3-gdc-token]=STR
	[--sider-prefix]=STR
	[--sider-threads]=INT
	[--sider-epsilon]=INT
	[--sider-min-pts]=INT
	[--sider-cache]=INT
	[--sider-max-dist]=INT
	[--sider-exon-frac]=FLOAT
	[--sider-align-frac]=FLOAT
	[--sider-quality]=INT
	[--sider-genotype]=INT
	[--gdc-jobs]=INT
)

# Join OPTIONS by ',' and set a needed value ':'
LONG_OPTIONS=$(sed -e 's/--//g' -e 's/ /:,/g' -e 's/$/:/' <<< "${!OPTIONS[@]}")

# Just print usage if there is no options at all
[[ $# -eq 0 ]] && { usage; exit; }

# Prepare getopt parsing
TEMP=$(getopt -n "$PROGNAME" -o 'h' --long "help,$LONG_OPTIONS" -- "$@")

# Parse getopt
eval set -- "$TEMP"
unset TEMP

# It is very annoying to write all this :(
while true; do
	case "$1" in
		-h|--help)            usage;                   exit    ;;
		--s3-output-bucket)   S3_OUTPUT_BUCKET="$2";   shift 2 ;;
		--s3-genome-file)     S3_GENOME_FILE="$2";     shift 2 ;;
		--s3-annotation-file) S3_ANNOTATION_FILE="$2"; shift 2 ;;
		--s3-manifest-file)   S3_MANIFEST_FILE="$2";   shift 2 ;;
		--s3-gdc-token)       S3_GDC_TOKEN="$2";       shift 2 ;;
		--sider-prefix)       SIDER_PREFIX="$2";       shift 2 ;;
		--sider-threads)      SIDER_THREADS="$2";      shift 2 ;;
		--sider-epsilon)      SIDER_EPSILON="$2";      shift 2 ;;
		--sider-min-pts)      SIDER_MIN_PTS="$2";      shift 2 ;;
		--sider-cache)        SIDER_CACHE="$2";        shift 2 ;;
		--sider-max-dist)     SIDER_MAX_DIST="$2";     shift 2 ;;
		--sider-exon-frac)    SIDER_EXON_FRAC="$2";    shift 2 ;;
		--sider-align-frac)   SIDER_ALIGN_FRAC="$2";   shift 2 ;;
		--sider-quality)      SIDER_QUALITY="$2";      shift 2 ;;
		--sider-genotype)     SIDER_GENOTYPE="$2";     shift 2 ;;
		--gdc-jobs)           GDC_JOBS="$2";           shift 2 ;;
		--)                   shift;                   break   ;;
		*)                    die "Internal error!"            ;;
	esac
done

# Save our analysis before it is too late ...
save_results() {
	say "Save results at $OUTPUT_DIR to $S3_OUTPUT_BUCKET/$OUTPUT_DIR"
	if ls -A "$OUTPUT_DIR" > /dev/null 2>&1; then
		aws s3 cp --quiet --recursive "$OUTPUT_DIR" "$S3_OUTPUT_BUCKET/$OUTPUT_DIR" \
			|| die "Failed to save $OUTPUT_DIR to $S3_OUTPUT_BUCKET"
	fi

	say "Clean up the mess"
	rm -rf "$OUTPUT_DIR" "$SIDER_DB_DIR" "$GDC_DIR" "$REFERENCE_DIR"

	say "FINITO"
}

# Trap EXIT to enforce saving results
trap "save_results" EXIT

# Warn if we received a signal to exit
exit_on_signal() {
	say "Received signal '$1'. Exiting ..."
	exit 255
}

# Trap killer signals
for SIG in SIGINT SIGQUIT SIGABRT SIGKILL SIGTERM; do
	trap "exit_on_signal $SIG" $SIG
done

say "Welcome to sideRETRO pipeline on AWS!"
say "Our batch id: $AWS_BATCH_JOB_ID"

say "Create base directories"
mkdir -p "$OUTPUT_DIR" "$SIDER_DB_DIR" "$GDC_DIR" "$REFERENCE_DIR" \
	|| die "Failed to create base directories"

say "Download genome file '$S3_GENOME_FILE'"
aws s3 cp --quiet "$S3_GENOME_FILE" "$REFERENCE_DIR" \
	|| die "Failed to download '$S3_GENOME_FILE'"

say "Download annotation file '$S3_ANNOTATION_FILE'"
aws s3 cp --quiet "$S3_ANNOTATION_FILE" "$REFERENCE_DIR" \
	|| die "Failed to download '$S3_ANNOTATION_FILE'"

say "Download MANIFEST file '$S3_MANIFEST_FILE'"
aws s3 cp --quiet "$S3_MANIFEST_FILE" "$GDC_DIR" \
	|| die "Failed to download '$S3_MANIFEST_FILE'"

say "Download GDC token '$S3_GDC_TOKEN'"
aws s3 cp --quiet "$S3_GDC_TOKEN" "$GDC_DIR" \
	|| die "Failed to download '$S3_GDC_TOKEN'"

# Set lazy variables
GENOME_FILE="${S3_GENOME_FILE##*/}"
ANNOTATION_FILE="${S3_ANNOTATION_FILE##*/}"
MANIFEST_FILE="${S3_MANIFEST_FILE##*/}"
GDC_TOKEN="${S3_GDC_TOKEN##*/}"

say "Run 'gdc-client' for MANIFEST file '$MANIFEST_FILE' and token '$GDC_TOKEN'"
chmod 600 "$GDC_DIR/$GDC_TOKEN" && gdc-client download \
	--color_off \
	--n-processes="$GDC_JOBS" \
	--token-file="$GDC_DIR/$GDC_TOKEN" \
	--manifest="$GDC_DIR/$MANIFEST_FILE" \
	--dir="$GDC_DIR" \
	--log-file="$OUTPUT_DIR/gdc-client.log" \
	> /dev/null \
	|| die "Failed to run 'gdc-client'"

say "Check all downloaded BAM files"
MISSING=($(comm -23 \
	<(tail -n +2 "$GDC_DIR/$MANIFEST_FILE" | awk '{print $1"/"$2}' | sort) \
	<(find "$GDC_DIR" -name "*.bam" -type 'f' | awk -F '/' '{print $(NF-1)"/"$NF}' | sort)))

# Return with an error code if not all files were downloaded
if [[ "${#MISSING[@]}" -gt 0 ]]; then
	die "Missing downloaded files from MANIFEST '$MANIFEST_FILE': ${MISSING[*]}"
fi

say "Get all BAM files into '${SIDER_PREFIX}_list.txt'"
find "$GDC_DIR" \
	-name "*.bam" \
	-type 'f' \
	> "$OUTPUT_DIR/${SIDER_PREFIX}_list.txt" \
	|| die "Failed to run 'find'"

if [[ $(wc -l < "$OUTPUT_DIR/${SIDER_PREFIX}_list.txt") -eq 0 ]]; then
	die "'$OUTPUT_DIR/${SIDER_PREFIX}_list.txt' is empty"
fi

say "Run 'sider process-sample' step"
sider process-sample \
	--quiet \
	--cache-size="$SIDER_CACHE" \
	--output-dir="$SIDER_DB_DIR" \
	--prefix="$SIDER_PREFIX" \
	--threads="$SIDER_THREADS" \
	--max-distance="$SIDER_MAX_DIST" \
	--exon-frac="$SIDER_EXON_FRAC" \
	--alignment-frac="$SIDER_ALIGN_FRAC" \
	--either \
	--phred-quality="$SIDER_QUALITY" \
	--log-file="$OUTPUT_DIR/${SIDER_PREFIX}_ps.log" \
	--annotation-file="$REFERENCE_DIR/$ANNOTATION_FILE" \
	--input-file="$OUTPUT_DIR/${SIDER_PREFIX}_list.txt" \
	|| die "Failed to run 'sider process-sample' step"

say "Run 'sider merge-call' step"
sider merge-call \
	--quiet \
	--cache-size="$SIDER_CACHE" \
	--epsilon="$SIDER_EPSILON" \
	--min-pts="$SIDER_MIN_PTS" \
	--genotype-support="$SIDER_GENOTYPE" \
	--log-file="$OUTPUT_DIR/${SIDER_PREFIX}_mc.log" \
	--threads="$SIDER_THREADS" \
	--blacklist-region="$REFERENCE_DIR/$ANNOTATION_FILE" \
	--phred-quality="$SIDER_QUALITY" \
	--in-place \
	"$SIDER_DB_DIR/$SIDER_PREFIX.db" \
	|| die "Failed to run 'sider merge-call' step"

say "Run 'sider make-vcf' step"
sider make-vcf \
	--quiet \
	--reference-file="$REFERENCE_DIR/$GENOME_FILE" \
	--log-file="$OUTPUT_DIR/${SIDER_PREFIX}_vcf.log" \
	--output-dir="$OUTPUT_DIR" \
	--prefix="$SIDER_PREFIX" \
	"$SIDER_DB_DIR/$SIDER_PREFIX.db" \
	|| die "Failed to run 'sider make-vcf' step"
