-include $(CONFIG_FILE)

S3_BUCKETS    := $(S3_BUCKET_REF)
ARN_BUCKETS   := $(foreach b,$(S3_BUCKETS),"arn:aws:s3:::$(b)")
ARN_BUCKETS   += $(foreach b,$(S3_BUCKETS),"arn:aws:s3:::$(b)/*")
RESOURCE_JS   := $(shell echo '$(ARN_BUCKETS)' | tr ' ' ',')
ARN_SERVICE   := arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole
ARN_INSTANCE  := arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role
ARN_INSTANCE  += arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
ARN_EXECUTION := arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

.PHONY: all

all: \
	$(addprefix @roles/,instance-profile.json instance_profile_attach.stamp) \
	$(addprefix @roles/,instance-role.json instance-custom-policy.json instance_attach.stamp) \
	$(addprefix @roles/,service-role.json service_attach.stamp) \
	$(addprefix @roles/,execution-role.json execution_attach.stamp)

%/execution_attach.stamp: %/execution-role.json
	for policy in $(ARN_EXECUTION); do \
		aws iam attach-role-policy \
			--role-name=$(IAM_EXECUTION_ROLE) \
			--policy-arn="$$policy"; \
	done
	touch $@

%/execution-role.json: policies/execution-trust-policy.json | %
	aws iam create-role \
		--role-name=$(IAM_EXECUTION_ROLE) \
		--assume-role-policy-document=file://$< \
		> $@

%/service_attach.stamp: %/service-role.json
	for policy in $(ARN_SERVICE); do \
		aws iam attach-role-policy \
			--role-name=$(IAM_SERVICE_ROLE) \
			--policy-arn="$$policy"; \
	done
	touch $@

%/service-role.json: policies/service-trust-policy.json | %
	aws iam create-role \
		--role-name=$(IAM_SERVICE_ROLE) \
		--assume-role-policy-document=file://$< \
		> $@

%/instance_profile_attach.stamp: %/instance_attach.stamp
	aws iam add-role-to-instance-profile \
		--instance-profile-name=$(IAM_INSTANCE_PROFILE) \
		--role-name=$(IAM_INSTANCE_ROLE)
	touch $@

%/instance-profile.json: | %
	aws iam create-instance-profile \
		--instance-profile-name=$(IAM_INSTANCE_PROFILE) \
		> $@

%/instance_attach.stamp: %/instance-custom-policy.json %/instance-role.json
	for policy in $(ARN_INSTANCE) $$(jq -r '.Policy.Arn' $<); do \
		aws iam attach-role-policy \
			--role-name=$(IAM_INSTANCE_ROLE) \
			--policy-arn="$$policy"; \
	done
	touch $@

%/instance-custom-policy.json: %/instance-s3-policy-resource.json
	aws iam create-policy \
		--policy-name=$(IAM_INSTANCE_POLICY) \
		--policy-document=file://$< \
		> $@

%/instance-role.json: policies/instance-trust-policy.json | %
	aws iam create-role \
		--role-name=$(IAM_INSTANCE_ROLE) \
		--assume-role-policy-document=file://$< \
		> $@

%/instance-s3-policy-resource.json: policies/instance-s3-policy.json | %
	jq '.Statement[-1].Resource |= [$(RESOURCE_JS)]' $< > $@

@roles:
	mkdir $@
