# xtradeb/docker/Makefile

DISTRO    = ubuntu
RELEASE   = jammy
ARCH      =
IMAGE     = xtradeb-$(RELEASE)$(_arch_tag)-$(USER)
CONTAINER = $(IMAGE)-con
HOSTNAME := $(shell hostname -s)
TOP      := $(shell cd .. && pwd)
CTX      := $(firstword $(SCRATCH) $(XDG_RUNTIME_DIR))/tmp.context

SRC        = /home/xtradeb/src
VOL_MOUNTS = \
	-v $(TOP):/external/xtradeb:ro \
	-v $(SRC):/external/src:ro \
	--tmpfs=/external/tmp:exec

APT_MIRROR =

ifeq "$(filter debian ubuntu, $(DISTRO))" ""
$(error invalid distribution "$(DISTRO)")
endif

ifeq "$(DISTRO)" "debian"
ifeq "$(RELEASE)" "sid"
$(error please use "unstable" instead of "sid")
endif
ifeq "$(filter bullseye bookworm trixie unstable, $(RELEASE))" ""
$(error invalid Debian release "$(RELEASE)")
endif
endif

ifeq "$(DISTRO)" "ubuntu"
ifeq "$(filter jammy kinetic lunar mantic noble oracular plucky questing, $(RELEASE))" ""
$(error invalid Ubuntu release "$(RELEASE)")
endif
endif

ifneq "$(ARCH)" ""
ifeq "$(filter amd64 arm64 armhf i386 ppc64el riscv64 s390x, $(ARCH))" ""
$(error invalid architecture "$(ARCH)")
endif
endif

_arch_tag  := $(if $(ARCH),-$(ARCH))
build_stamp = build-$(RELEASE)-$(HOSTNAME)$(_arch_tag).stamp

ifneq "$(ARCH)" ""
docker_arch := $(subst armhf,arm/v7,$(subst ppc64el,ppc64le,$(ARCH)))
platform_opt = --platform=linux/$(docker_arch)
else
platform_opt =
endif

CCACHE_DIR := $(firstword $(wildcard $(SCRATCH)/xtradeb/ccache$(_arch_tag) /dept/ter/speech/$(USER)/xtradeb/ccache$(_arch_tag)))
ifneq "$(CCACHE_DIR)" ""
VOL_MOUNTS += -v $(CCACHE_DIR):/external/ccache
endif

# Don't use "docker attach", as the container will be stopped when the
# shell exits. We want that to happen only for the initial shell.
#
run: $(build_stamp)
	@if docker container inspect $(CONTAINER) >/dev/null 2>&1; then \
		set -x; \
		docker container exec -it $(CONTAINER) /bin/bash; \
	else \
		set -x; \
		docker container run -it --rm $(platform_opt) \
			--env=APT_MIRROR=$(APT_MIRROR) \
			--name=$(CONTAINER) \
			--hostname=$(CONTAINER) \
			--pids-limit -1 \
			--cap-add=SYS_PTRACE \
			$(VOL_MOUNTS) \
			$(IMAGE); \
	fi

build: $(build_stamp)

$(build_stamp): Dockerfile
	rm -rf $(CTX)
	mkdir $(CTX)
	cp -p $< $(CTX)
	cp -p hybrid-*.sh $(CTX)
	touch $(CTX)/dummy
	TMPDIR=$(CTX) docker build $(platform_opt) \
		--build-arg DISTRO_RELEASE=$(DISTRO):$(RELEASE) \
		$(if $(APT_MIRROR),--build-arg APT_MIRROR=$(APT_MIRROR)) \
		--network=host \
		--progress plain \
		--tag $(IMAGE) \
		$(CTX)
	rm -rf $(CTX)
	docker container run --rm $(platform_opt) $(IMAGE) true
	touch $@

clean:
	-docker image rm $(IMAGE)
	rm -f $(build_stamp)
	rm -rf $(CTX)

.PHONY: run build clean

# end xtradeb/docker/Makefile
