-include $(CONFIG_FILE)

DIR       := @run
NUM_JOBS  := $(shell perl -mPOSIX=ceil -ae 'END{print ceil(($$.-1)/$(WORK_BATCH_SIZE))}' $(WORK_MANIFEST_FILE))
MANIFESTS := $(shell for i in $$(seq -f '%03.0f' $(NUM_JOBS)); do echo "$(DIR)/MANIFEST.batch$${i}"; done)
JOBS      := $(shell for i in $$(seq -f '%03.0f' $(NUM_JOBS)); do echo "$(DIR)/batch$${i}.json"; done)

.PHONY: all

all: $(JOBS)

$(DIR)/%.json: $(DIR)/worker.stamp $(DIR)/command_%.json
	aws batch submit-job \
		--job-name=$* \
		--job-queue=$(BATCH_JOB_QUEUE) \
		--job-definition=$(BATCH_JOB_DEF) \
		--container-overrides="$$(cat $(word 2,$^))" \
		> $@

$(DIR)/command_%.json: $(DIR)/MANIFEST.%.stamp
	echo -ne \
		'task_run.sh\n' \
		'  --s3-output-bucket\ns3://$(S3_BUCKET_OUTPUT)\n' \
		'  --s3-genome-file\ns3://$(S3_BUCKET_REF)/$(notdir $(GENOME_PATH))\n' \
		'  --s3-annotation-file\ns3://$(S3_BUCKET_REF)/$(notdir $(ANNOTATION_PATH))\n' \
		'  --s3-manifest-file\ns3://$(S3_BUCKET_INPUT)/$(notdir $(basename $<))\n' \
		'  --s3-gdc-token\ns3://$(S3_BUCKET_REF)/$(notdir $(GDC_TOKEN_PATH))\n' \
		'  --sider-prefix\n$(SIDER_PREFIX)\n' \
		'  --sider-threads\n$(SIDER_THREADS)\n' \
		'  --sider-epsilon\n$(SIDER_EPSILON)\n' \
		'  --sider-min-pts\n$(SIDER_MIN_PTS)\n' \
		'  --sider-cache\n$(SIDER_CACHE)\n' \
		'  --sider-max-dist\n$(SIDER_MAX_DIST)\n' \
		'  --sider-exon-frac\n$(SIDER_EXON_FRAC)\n' \
		'  --sider-align-frac\n$(SIDER_ALIGN_FRAC)\n' \
		'  --sider-quality\n$(SIDER_QUALITY)\n' \
		'  --sider-genotype\n$(SIDER_GENOTYPE)\n' \
		'  --gdc-jobs\n$(GDC_JOBS)\n' | sed 's/ //g' | jq -Rcn '.command = [inputs]' > $@

$(DIR)/worker.stamp: worker.sh | $(DIR)
	aws s3 cp --quiet $< s3://$(S3_BUCKET_REF)
	touch $@

$(DIR)/MANIFEST.%.stamp: $(DIR)/MANIFEST.%
	aws s3 cp --quiet $< s3://$(S3_BUCKET_INPUT)
	touch $@

$(MANIFESTS) &: $(DIR)/header.txt $(DIR)/content.txt
	split \
		--lines=$(WORK_BATCH_SIZE) \
		--suffix-length=3 \
		--numeric-suffixes=1 \
		$(word 2,$^) $(DIR)/MANIFEST.batch
	find $(DIR) \
		-type f \
		-name 'MANIFEST.batch*' \
		-exec bash -c 'cat $(word 1,$^) {} > {}.$$$$ && mv {}.$$$$ {}' ';'
	rm -f $^

$(DIR)/content.txt: $(WORK_MANIFEST_FILE) | $(DIR)
	tail -n+2 $< > $@

$(DIR)/header.txt: $(WORK_MANIFEST_FILE) | $(DIR)
	head -n1 $< > $@

$(DIR):
	mkdir $@
