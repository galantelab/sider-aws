SHELL         := bash
MAKE_DIR      := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
S3_DIR        := $(MAKE_DIR)s3
ECR_DIR       := $(MAKE_DIR)ecr
IAM_DIR       := $(MAKE_DIR)iam
CONFIG_FILE   ?= config.mk
CONFIG_FILE   := $(abspath $(CONFIG_FILE))

include $(CONFIG_FILE)

export \
	SHELL \
	MAKE_DIR \
	S3_DIR \
	ECR_DIR \
	IAM_DIR \
	CONFIG_FILE

.PHONY: all

all: s3 ecr iam

.PHONY: s3

s3:
	$(MAKE) -C $(S3_DIR)

.PHONY: ecr

ecr:
	$(MAKE) -C $(ECR_DIR)

.PHONY: iam

iam:
	$(MAKE) -C $(IAM_DIR)
