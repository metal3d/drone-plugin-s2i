REPO:=metal3d
IMG:=plugin-s2i

MAJOR=v2
MINOR=$(MAJOR).0
REL=$(MINOR).1
IMAGE=$(REPO)/$(IMG)


build:
	docker build -t $(IMAGE):$(REL) .

tag:
	docker tag $(IMAGE):$(REL) $(IMAGE):$(MINOR)
	docker tag $(IMAGE):$(REL) $(IMAGE):$(MAJOR)
	docker tag $(IMAGE):$(REL) $(IMAGE):latest

push: tag
	docker push $(IMAGE):$(REL)
	docker push $(IMAGE):$(MINOR)
	docker push $(IMAGE):$(MAJOR)
	docker push $(IMAGE):latest

