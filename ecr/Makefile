-include $(CONFIG_FILE)

.PHONY: all

all: @$(ECR_IMAGE)/ecr.stamp

%/ecr.stamp: %/ecr_uri.txt %/tag.stamp
	eval $$(aws ecr get-login | sed 's/-e none//')
	docker push $$(cat $<):$(ECR_IMAGE_TAG)
	docker logout
	touch $@

%/tag.stamp: %/ecr_uri.txt %/build.stamp
	docker tag $(ECR_IMAGE):$(ECR_IMAGE_TAG) $$(cat $<):$(ECR_IMAGE_TAG)
	touch $@

%/build.stamp: Dockerfile fetch_and_run.sh
	docker buildx build -t $(ECR_IMAGE):$(ECR_IMAGE_TAG) .
	touch $@

%/ecr_uri.txt: %/ecr.json
	awk '/repositoryUri/ {gsub(/"/,""); print $$2}' $< > $@

.PRECIOUS: %/ecr.json

%/ecr.json: | %
	aws ecr create-repository --repository-name $(ECR_IMAGE) > $@

@$(ECR_IMAGE):
	mkdir $@
