-include $(CONFIG_FILE)

.PHONY: all

all: key-pair vpc launch-template

.PHONY: launch-template

launch-template: @launch_template/launch_template.json

%/launch_template.json: %/launch_template_data.json
	aws ec2 create-launch-template \
		--launch-template-name=$(EC2_LAUNCH_TEMPLATE) \
		--version-description="Batch Job Template for sider" \
		--launch-template-data="$$(cat $<)" \
		> $@

%/launch_template_data.json: %/user_data.base64
	echo -e \
		'{\n' \
		' "ImageId": "$(EC2_IMAGE_ID)",\n' \
		' "InstanceType": "$(EC2_INSTANCE_TYPE)",\n' \
		' "KeyName": "$(EC2_KEY_PAIR)",\n' \
		' "Monitoring": {\n' \
		'   "Enabled": true\n' \
		' },\n' \
		' "BlockDeviceMappings": [\n' \
		'   {\n' \
		'     "DeviceName": "/dev/sdf",\n' \
		'     "Ebs": {\n' \
		'       "DeleteOnTermination": true,\n' \
		'       "VolumeSize": $(EBS_VOLUME_SIZE),\n' \
		'       "VolumeType": "$(EBS_VOLUME_TYPE)"\n' \
		'     }\n' \
		'   }\n' \
		' ],\n' \
		' "UserData":' "\"$$(cat $<)\"\n}" > $@

%/user_data.base64: data/write-mime-multipart.py data/user_data.sh | %
	python $^ | base64 -w0 > $@

@launch_template:
	mkdir $@

.PHONY: vpc

vpc: \
	$(addprefix @vpc/,vpc.json gateway.json attach.stamp) \
	$(addprefix @vpc/,route_table.json route.json) \
	$(addprefix @vpc/,security_group.json authorize_security_group.stamp) \
	$(foreach z,$(AWS_REGION_ZONES),@vpc/subnet_$(z).json) \
	$(foreach z,$(AWS_REGION_ZONES),@vpc/association_$(z).json)

%/authorize_security_group.stamp: %/security_group.json
	aws ec2 authorize-security-group-ingress \
		--group-id=$$(jq -r '.GroupId' $<) \
		--protocol=tcp \
		--port=22 \
		--cidr=0.0.0.0/0
	touch $@

%/security_group.json: %/vpc.json
	aws ec2 create-security-group \
		--group-name=$(EC2_SECURITY_GROUP) \
		--vpc-id=$$(jq -r '.Vpc.VpcId' $<) \
		--description="Security group for sider pipeline" \
		> $@

define association_tt =
	aws ec2 associate-route-table \
		--subnet-id=$$(jq -r '.Subnet.SubnetId' $(word 1, $^)) \
		--route-table-id=$$(jq -r '.RouteTable.RouteTableId' $(word 2, $^)) \
		> $@
endef

%/association_a.json: %/subnet_a.json %/route_table.json
	$(call association_tt)

%/association_b.json: %/subnet_b.json %/route_table.json
	$(call association_tt)

%/association_c.json: %/subnet_c.json %/route_table.json
	$(call association_tt)

%/association_d.json: %/subnet_d.json %/route_table.json
	$(call association_tt)

%/association_e.json: %/subnet_e.json %/route_table.json
	$(call association_tt)

%/association_f.json: %/subnet_f.json %/route_table.json
	$(call association_tt)

%/route.json: %/route_table.json %/gateway.json
	aws ec2 create-route \
		--route-table-id=$$(jq -r '.RouteTable.RouteTableId' $(word 1, $^)) \
		--destination-cidr-block=0.0.0.0/0 \
		--gateway-id=$$(jq -r '.InternetGateway.InternetGatewayId' $(word 2, $^)) \
		> $@

%/route_table.json: %/vpc.json
	aws ec2 create-route-table --vpc-id=$$(jq -r '.Vpc.VpcId' $<) > $@

%/attach.stamp: %/vpc.json %/gateway.json
	aws ec2 attach-internet-gateway \
		--vpc-id=$$(jq -r '.Vpc.VpcId' $(word 1, $^)) \
		--internet-gateway-id=$$(jq -r '.InternetGateway.InternetGatewayId' $(word 2, $^))
	touch $@

%/gateway.json: | %
	aws ec2 create-internet-gateway > $@

define subnet_tt =
	aws ec2 create-subnet \
		--vpc-id=$$(jq -r '.Vpc.VpcId' $<) \
		--cidr-block=10.0.$(2).0/24 \
		--availability-zone=$(AWS_REGION)$(1) \
		> $@
	aws ec2 modify-subnet-attribute \
		--subnet-id=$$(jq -r '.Subnet.SubnetId' $@) \
		--map-public-ip-on-launch
endef

%/subnet_a.json: %/vpc.json
	$(call subnet_tt,a,1)

%/subnet_b.json: %/vpc.json
	$(call subnet_tt,b,2)

%/subnet_c.json: %/vpc.json
	$(call subnet_tt,c,3)

%/subnet_d.json: %/vpc.json
	$(call subnet_tt,d,4)

%/subnet_e.json: %/vpc.json
	$(call subnet_tt,e,5)

%/subnet_f.json: %/vpc.json
	$(call subnet_tt,f,6)

%/vpc.json: | %
	aws ec2 create-vpc --cidr-block=10.0.0.0/16 > $@

@vpc:
	mkdir $@

.PHONY: key-pair

key-pair: $(addprefix @key-pair/,key-pair.json $(EC2_KEY_PAIR).pem)

%/$(EC2_KEY_PAIR).pem: %/key-pair.json
	jq -r '.KeyMaterial' $< > $@
	chmod 400 $@

%/key-pair.json: | %
	aws ec2 create-key-pair --key-name=$(EC2_KEY_PAIR) > $@

@key-pair:
	mkdir $@
