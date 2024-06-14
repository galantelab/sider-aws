-include $(CONFIG_FILE)

.PHONY: all

all: compute-environment

.PHONY: compute-environment

compute-environment: @compute_environment/compute_environment.json

%/compute_environment.json: %/compute_resources.json
	aws batch create-compute-environment \
		--compute-environment-name=$(BATCH_COMP_ENV) \
		--type=MANAGED \
		--state=ENABLED \
		--service-role=$(IAM_SERVICE_ROLE) \
		--compute-resources="$$(cat $<)" \
		> $@

%/compute_resources.json: %/subnets.json
	echo -e \
		'{\n' \
		' "type": "EC2",\n' \
		' "minvCpus": $(BATCH_MINVCPUS),\n' \
		' "desiredvCpus": $(BATCH_DESIREDVCPUS),\n' \
		' "maxvCpus": $(BATCH_MAXVCPUS),\n' \
		' "instanceTypes": ["$(EC2_INSTANCE_TYPE)"],\n' \
		' "subnets":' "$$(cat $<),\n" \
		' "securityGroupIds": ["$(EC2_SECURITY_GROUP)"],\n' \
		' "instanceRole": "$(IAM_INSTANCE_ROLE)",\n' \
		' "launchTemplate": {\n' \
		'   "launchTemplateName": "$(EC2_LAUNCH_TEMPLATE)",\n' \
		'   "version": "$$Latest"\n' \
		' }\n}' > $@

%/subnets.json: $(shell find $(EC2_DIR)/@vpc -name 'subnet_*.json') | %
	jq '.Subnet.SubnetId' $^ | jq -nc '[inputs]' > $@

@compute_environment:
	mkdir $@
