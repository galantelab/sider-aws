#!/usr/bin/env bash

set -e

[[ -z "$1" ]] && { echo "Usage: $0 <JOBID>" >&2; exit 1; }

job_id="$1"

container_instance_arn=$(aws batch describe-jobs \
	--jobs="$job_id" \
	--query='jobs[0].container.containerInstanceArn' \
	--output=text)

tmp=${container_instance_arn#*/}
cluster_name=${tmp%/*}

ec2_id=$(aws ecs describe-container-instances \
	--container-instances="$container_instance_arn" \
	--cluster="$cluster_name" \
	--query="containerInstances[0].ec2InstanceId" \
	--output=text)

ip_address=$(aws ec2 describe-instances \
	--instance-ids="$ec2_id" \
	--query='Reservations[0].Instances[0].{"PublicIP":PublicIpAddress}' \
	--output=text)

echo "$ip_address"
