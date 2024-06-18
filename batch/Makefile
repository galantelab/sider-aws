-include $(CONFIG_FILE)

.PHONY: all

all: compute-environment job-queue

.PHONY: job-queue

job-queue: $(addprefix @job_queue/,job_queue.json job_definition.json)

%/job_definition.json: %/container_properties.json
	aws batch register-job-definition \
		--job-definition-name=$(BATCH_JOB_DEF) \
		--type=container \
		--container-properties="$$(cat $<)" \
		> $@

%/container_properties.json: %/ecr_image.json %/execution_role.json
	echo -e \
		'{\n' \
		' "image":' "$$(cat $(word 1,$^)),\n" \
		' "command": ["fetch_and_run.sh"],\n' \
		' "executionRoleArn":' "$$(cat $(word 2,$^)),\n" \
		' "user": "$(ECR_USER):$(ECR_USER)",\n' \
		' "resourceRequirements": [\n' \
		'   {\n' \
		'     "value": "$(EC2_INSTANCE_CPUS)",\n' \
		'     "type": "VCPU"\n' \
		'   },\n' \
		'   {\n' \
		'     "value": "$(EC2_INSTANCE_MEM)",\n' \
		'     "type": "MEMORY"\n' \
		'   }\n' \
		' ],\n' \
		' "environment": [\n' \
		'   {\n' \
		'     "name": "BATCH_FILE_S3_URL",\n' \
		'     "value": "s3://$(S3_BUCKET_REF)/worker.sh"\n' \
		'   },\n' \
		'   {\n' \
		'     "name": "BATCH_FILE_TYPE",\n' \
		'     "value": "script"\n' \
		'   }\n' \
		' ],\n' \
		' "logConfiguration": {\n' \
		'   "logDriver": "awslogs",\n' \
		'   "options": {\n' \
		'     "awslogs-group": "/aws/batch/job",\n' \
		'     "awslogs-region": "$(AWS_REGION)",\n' \
		'     "awslogs-stream-prefix": "sider"\n' \
		'   }\n' \
		' },\n' \
		' "volumes": [\n' \
		'   {\n' \
		'     "host": {\n' \
		'       "sourcePath": "$(EBS_MOUNT_DIR)"\n' \
		'     },\n' \
		'     "name": "workdir-volume"\n' \
		'   }\n' \
		' ],\n' \
		' "mountPoints": [\n' \
		'   {\n' \
		'     "sourceVolume": "workdir-volume",\n' \
		'     "containerPath": "$(ECR_HOME)",\n' \
		'     "readOnly": false\n' \
		'   }\n' \
		' ]\n}' > $@

%/execution_role.json: $(MAKE_DIR)iam/@roles/execution-role.json | %
	jq '.Role.Arn' $< > $@

%/ecr_image.json: $(MAKE_DIR)ecr/@siderp/ecr.json | %
	echo "\"$$(jq -r '.repository.repositoryUri' $<):$(ECR_IMAGE_TAG)\"" > $@

%/job_queue.json: | %
	aws batch create-job-queue \
		--job-queue-name=$(BATCH_JOB_QUEUE) \
		--state=ENABLED \
		--priority=1 \
		--compute-environment-order='[{"order": 1, "computeEnvironment": "$(BATCH_COMP_ENV)"}]' \
		> $@

@job_queue:
	mkdir $@

.PHONY: compute-environment

compute-environment: @compute_environment/compute_environment.json

%/compute_environment.json: check_env_status.sh %/compute_resources.json
	aws batch create-compute-environment \
		--compute-environment-name=$(BATCH_COMP_ENV) \
		--type=MANAGED \
		--state=ENABLED \
		--service-role=$(IAM_SERVICE_ROLE) \
		--compute-resources="$$(cat $(word 2,$^))" \
		> $@
	bash $(word 1,$^) $(BATCH_COMP_ENV)

%/compute_resources.json: %/subnets.json %/sgs.json
	echo -e \
		'{\n' \
		' "type": "EC2",\n' \
		' "minvCpus": $(BATCH_MINVCPUS),\n' \
		' "desiredvCpus": $(BATCH_DESIREDVCPUS),\n' \
		' "maxvCpus": $(BATCH_MAXVCPUS),\n' \
		' "instanceTypes": ["$(EC2_INSTANCE_TYPE)"],\n' \
		' "subnets":' "$$(cat $(word 1,$^)),\n" \
		' "securityGroupIds":' "$$(cat $(word 2,$^)),\n" \
		' "instanceRole": "$(IAM_INSTANCE_PROFILE)",\n' \
		' "launchTemplate": {\n' \
		'   "launchTemplateName": "$(EC2_LAUNCH_TEMPLATE)",\n' \
		'   "version": "$$Latest"\n' \
		' }\n}' > $@

%/sgs.json: $(MAKE_DIR)ec2/@vpc/security_group.json | %
	jq '.GroupId' $< | jq -nc '[inputs]' > $@

%/subnets.json: $(shell find $(MAKE_DIR)ec2/@vpc -name 'subnet_*.json') | %
	jq '.Subnet.SubnetId' $^ | jq -nc '[inputs]' > $@

@compute_environment:
	mkdir $@
