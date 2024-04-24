SHELL         := bash
MAKE_DIR      := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
S3_DIR        := s3
CONFIG_FILE   ?= config.mk
CONFIG_FILE   := $(abspath $(CONFIG_FILE))

include $(CONFIG_FILE)

export \
	SHELL \
	MAKE_DIR \
	S3_DIR \
	CONFIG_FILE

.PHONY: all

all: s3

.PHONY: s3

s3:
	$(MAKE) -C $(S3_DIR)
