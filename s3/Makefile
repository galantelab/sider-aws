-include $(CONFIG_FILE)

BDIRS  := @$(S3_BUCKET_REF) @$(S3_BUCKET_INPUT) @$(S3_BUCKET_OUTPUT)
FILES  := $(GENOME_PATH) $(ANNOTATION_PATH) $(GDC_TOKEN_PATH)
STAMPS := $(addprefix @$(S3_BUCKET_REF)/,$(addsuffix .stamp,$(notdir $(FILES))))

.PHONY: all

all: $(STAMPS) $(BDIRS)

$(STAMPS): | @$(S3_BUCKET_REF)

define s3_cp_tt =
@$(S3_BUCKET_REF)/$(notdir $(1)).stamp:
	aws s3 cp --quiet $(1) s3://$(S3_BUCKET_REF)
	touch @$(S3_BUCKET_REF)/$(notdir $(1)).stamp
endef

$(foreach file, $(FILES), $(eval $(call s3_cp_tt,$(file))))

$(BDIRS):
	if ! aws s3api head-bucket --bucket=$(subst @,,$@) 2> /dev/null; then \
		aws s3api create-bucket --bucket=$(subst @,,$@) > /dev/null; \
	fi
	mkdir $@
