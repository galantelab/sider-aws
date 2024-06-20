SHELL         := bash
MAKE_DIR      := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SUBDIRS       := s3 ecr iam ec2 batch work
CONFIG_FILE   ?= config.mk
CONFIG_FILE   := $(abspath $(CONFIG_FILE))

include $(CONFIG_FILE)

export \
	SHELL \
	MAKE_DIR \
	CONFIG_FILE

.PHONY: all $(SUBDIRS)

all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@ $(role)
