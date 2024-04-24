-include $(CONFIG_FILE)

FILES  := $(GENOME_PATH) $(ANNOTATION_PATH)
STAMPS := $(notdir $(addsuffix .stamp,$(FILES)))

$(STAMPS): | $(S3_BUCKET_REF)

define s3_cp_tt =
$(notdir $(1)).stamp:
	aws s3 cp --quiet $(1) s3://$(S3_BUCKET_REF)
	touch $(notdir $(1)).stamp
endef

$(foreach file, $(FILES), $(eval $(call s3_cp_tt,$(file),$(notdir $(file)))))

$(S3_BUCKET_REF):
	if ! aws s3api head-bucket --bucket=$@ 2> /dev/null; then \
		aws s3api create-bucket --bucket=$@; \
	fi
