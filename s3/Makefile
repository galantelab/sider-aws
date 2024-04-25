-include $(CONFIG_FILE)

FILES  := $(GENOME_PATH) $(ANNOTATION_PATH)
STAMPS := $(addprefix $(S3_BUCKET_REF)/,$(addsuffix .stamp,$(notdir $(FILES))))

.PHONY: all

all: $(STAMPS)

$(STAMPS): | $(S3_BUCKET_REF)

define s3_cp_tt =
$(S3_BUCKET_REF)/$(notdir $(1)).stamp:
	aws s3 cp --quiet $(1) s3://$(S3_BUCKET_REF)
	touch $(S3_BUCKET_REF)/$(notdir $(1)).stamp
endef

$(foreach file, $(FILES), $(eval $(call s3_cp_tt,$(file))))

$(S3_BUCKET_REF):
	if ! aws s3api head-bucket --bucket=$@ 2> /dev/null; then \
		aws s3api create-bucket --bucket=$@; \
	fi
	mkdir $@
