-include $(CONFIG_FILE)

AWS_REGION_ZONES := a b c d e f

.PHONY: all

all: key-pair vpc

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

%/subnet_a.json: %/vpc.json
	aws ec2 create-subnet \
		--vpc-id=$$(jq -r '.Vpc.VpcId' $<) \
		--cidr-block=10.0.1.0/24 \
		--availability-zone=$(AWS_REGION)a \
		> $@

%/subnet_b.json: %/vpc.json
	aws ec2 create-subnet \
		--vpc-id=$$(jq -r '.Vpc.VpcId' $<) \
		--cidr-block=10.0.2.0/24 \
		--availability-zone=$(AWS_REGION)b \
		> $@

%/subnet_c.json: %/vpc.json
	aws ec2 create-subnet \
		--vpc-id=$$(jq -r '.Vpc.VpcId' $<) \
		--cidr-block=10.0.3.0/24 \
		--availability-zone=$(AWS_REGION)c \
		> $@

%/subnet_d.json: %/vpc.json
	aws ec2 create-subnet \
		--vpc-id=$$(jq -r '.Vpc.VpcId' $<) \
		--cidr-block=10.0.4.0/24 \
		--availability-zone=$(AWS_REGION)d \
		> $@

%/subnet_e.json: %/vpc.json
	aws ec2 create-subnet \
		--vpc-id=$$(jq -r '.Vpc.VpcId' $<) \
		--cidr-block=10.0.5.0/24 \
		--availability-zone=$(AWS_REGION)e \
		> $@

%/subnet_f.json: %/vpc.json
	aws ec2 create-subnet \
		--vpc-id=$$(jq -r '.Vpc.VpcId' $<) \
		--cidr-block=10.0.6.0/24 \
		--availability-zone=$(AWS_REGION)f \
		> $@

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
