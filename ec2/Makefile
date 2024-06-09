-include $(CONFIG_FILE)

.PHONY: all

all: $(addprefix @key-pair/,key-pair.json $(EC2_KEY_PAIR).pem)

%/$(EC2_KEY_PAIR).pem: %/key-pair.json
	jq -r '.KeyMaterial' $< > $@
	chmod 400 $@

%/key-pair.json: | %
	aws ec2 create-key-pair --key-name=$(EC2_KEY_PAIR) > $@

@key-pair:
	mkdir $@
