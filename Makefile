SHELL         := bash
MAKE_DIR      := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
S3_DIR        := $(MAKE_DIR)s3
ECR_DIR       := $(MAKE_DIR)ecr
ROLES_DIR     := $(MAKE_DIR)roles
CONFIG_FILE   ?= config.mk
CONFIG_FILE   := $(abspath $(CONFIG_FILE))

include $(CONFIG_FILE)

export \
	SHELL \
	MAKE_DIR \
	S3_DIR \
	ECR_DIR \
	ROLES_DIR \
	CONFIG_FILE

.PHONY: all

all: s3 ecr roles

.PHONY: s3

s3:
	$(MAKE) -C $(S3_DIR)

.PHONY: ecr

ecr:
	$(MAKE) -C $(ECR_DIR)

.PHONY: roles

roles:
	$(MAKE) -C $(ROLES_DIR)
