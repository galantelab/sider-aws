-include $(CONFIG_FILE)

.PHONY: all

all: @$(ECR_IMAGE)/ecr.stamp

%/ecr.stamp: %/ecr.json %/tag.stamp
	aws ecr get-login-password \
		| docker login \
			--username=AWS \
			--password-stdin \
			$$(jq -r '.repository.repositoryUri' $< | sed 's|/$(ECR_IMAGE)$$||')
	docker push $$(jq -r '.repository.repositoryUri' $<):$(ECR_IMAGE_TAG)
	docker logout
	touch $@

%/tag.stamp: %/ecr.json %/build.stamp
	docker tag \
		$(ECR_IMAGE):$(ECR_IMAGE_TAG) \
		$$(jq -r '.repository.repositoryUri' $<):$(ECR_IMAGE_TAG)
	touch $@

%/build.stamp: Dockerfile fetch_and_run.sh
	docker buildx build \
		--build-arg='user=$(ECR_USER)' \
		--build-arg='uid=$(ECR_UID)' \
		--build-arg='home=$(ECR_HOME)' \
		--tag=$(ECR_IMAGE):$(ECR_IMAGE_TAG) \
		.
	touch $@

.PRECIOUS: %/ecr.json

%/ecr.json: | %
	aws ecr create-repository --repository-name $(ECR_IMAGE) > $@

@$(ECR_IMAGE):
	mkdir $@
