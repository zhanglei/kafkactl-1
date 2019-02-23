# https://opensource.com/article/18/8/what-how-makefile

.DEFAULT_GOAL := clean

export GO111MODULE=on

LATEST=$(shell curl -s https://github.com/jbvmio/kafkactl/releases/latest | awk -F '/' '/releases/{print $$8}' | awk -F '"' '{print $$1}')
LATESTMAJ=$(shell echo $(LATEST) | cut -d '.' -f 1)
LATESTMIN=$(shell echo $(LATEST) | cut -d '.' -f 2)
LATESTPAT=$(shell echo $(LATEST) | cut -d '.' -f 3)
NEXTPAT=$(shell echo $(LATESTPAT) + 1 | bc)
NEXTVER="$(LATESTMAJ).$(LATESTMIN).$(NEXTPAT)"

YTIME=$(shell date -j -f "%b %d %Y %T" "Jan 1 2019 00:00:00" "+%s")
BT=$(shell date +%s)
GCT=$(shell git rev-list -1 HEAD --timestamp | awk '{print $$1}')
GC=$(shell git rev-list -1 HEAD --abbrev-commit)
REV=$(shell echo $(GCT)-$(YTIME) | bc)
FNAME="kafkactl_$(LATEST)+$(REV)"

ld_flags := "-X github.com/jbvmio/kafkactl/cli/cmd.latestMajor=$(LATESTMAJ) \
-X github.com/jbvmio/kafkactl/cli/cmd.latestMinor=$(LATESTMIN) \
-X github.com/jbvmio/kafkactl/cli/cmd.latestPatch=$(LATESTPAT) \
-X github.com/jbvmio/kafkactl/cli/cmd.release=false \
-X github.com/jbvmio/kafkactl/cli/cmd.nextRelease=$(NEXTVER) \
-X github.com/jbvmio/kafkactl/cli/cmd.revision=$(REV) \
-X github.com/jbvmio/kafkactl/cli/cmd.buildTime=$(BT) \
-X github.com/jbvmio/kafkactl/cli/cmd.commitHash=$(GC)"

.PHONY: build
build: 
	GOOS=darwin ARCH=amd64 go build -ldflags $(ld_flags) -o kafkactl.darwin
	GOOS=linux ARCH=amd64 go build -ldflags $(ld_flags) -o kafkactl.linux
	GOOS=darwin ARCH=amd64 go build -ldflags $(ld_flags) -o kafkactl.exe

.PHONY: clean
clean: build
	rm -f kafkactl.darwin
	rm -f kafkactl.linux
	rm -f kafkactl.exe

# usage make version=0.0.4 release
.PHONY: release
release:
	git add .
	git commit -m "release $(NEXTVER)"
	git tag -a $(NEXTVER) -m "release $(NEXTVER)"
	git push origin
	git push origin $(NEXTVER)
