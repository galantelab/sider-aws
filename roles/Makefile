-include $(CONFIG_FILE)

S3_BUCKETS  := $(S3_BUCKET_REF)
ARN_BUCKETS := $(foreach b,$(S3_BUCKETS),"arn:aws:s3:::$(b)")
RESOURCE_JS := $(shell echo '$(ARN_BUCKETS)' | tr ' ' ',')

.PHONY: all

all: $(addprefix @iam/,role.json policy.json attach.stamp)

%/attach.stamp: %/policy.json %/role.json
	aws iam attach-role-policy \
		--role-name=$(IAM_ROLE_BATCH) \
		--policy-arn=$$(jq -r '.Policy.Arn' $<)
	touch $@

%/policy.json: %/aws-batch-policy-resource.json
	aws iam create-policy \
		--policy-name=$(IAM_POLICY_BATCH) \
		--policy-document=file://$< \
		> $@

%/role.json: policies/trust-policy.json | %
	aws iam create-role \
		--role-name=$(IAM_ROLE_BATCH) \
		--assume-role-policy-document=file://$< \
		> $@

%/aws-batch-policy-resource.json: policies/aws-batch-policy.json | %
	jq '.Statement[-1].Resource |= [$(RESOURCE_JS)]' $< > $@

@iam:
	mkdir $@
